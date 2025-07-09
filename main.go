package main

import "C"

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/dgraph-io/ristretto"
	"github.com/google/cel-go/cel"
	"github.com/google/cel-go/ext"
)

// Ristretto cache for compiled CEL programs
var programCache *ristretto.Cache

// Ristretto cache for parsed JSON data
var jsonCache *ristretto.Cache

// Initialize caches with configurable sizes
//
//export pg_init_caches
func pg_init_caches(programCacheMB int, jsonCacheMB int) {
	var err error

	// Convert MB to bytes
	programCacheSize := int64(programCacheMB) * 1024 * 1024
	jsonCacheSize := int64(jsonCacheMB) * 1024 * 1024

	// Initialize program cache
	programCache, err = ristretto.NewCache(&ristretto.Config{
		NumCounters: 1e7,              // number of keys to track frequency of (10M)
		MaxCost:     programCacheSize, // maximum cost of cache (configurable)
		BufferItems: 64,               // number of keys per Get buffer
	})
	if err != nil {
		log.Fatalf("Failed to create program cache: %v", err)
	}

	// Initialize JSON cache
	jsonCache, err = ristretto.NewCache(&ristretto.Config{
		NumCounters: 1e6,           // number of keys to track frequency of (1M)
		MaxCost:     jsonCacheSize, // maximum cost of cache (configurable)
		BufferItems: 64,            // number of keys per Get buffer
	})
	if err != nil {
		log.Fatalf("Failed to create JSON cache: %v", err)
	}
}

func init() {
	// Default initialization for standalone usage
	// In PostgreSQL, pg_init_caches will be called with configured values
	pg_init_caches(256, 128) // 256MB program cache, 128MB JSON cache
}

// Create a CEL environment with common extensions
func createCELEnv() (*cel.Env, error) {
	return cel.NewEnv(
		// Enable useful extensions
		ext.Strings(),
		ext.Math(),
		ext.Lists(),
		ext.Bindings(),
		ext.Protos(),
		ext.Encoders(),
		ext.Sets(),
	)
}

//export pg_cel_eval
func pg_cel_eval(expressionStr *C.char, dataStr *C.char) *C.char {
	// Convert C strings to Go strings
	exprString := C.GoString(expressionStr)
	dataString := C.GoString(dataStr)

	// Try to get compiled program from cache
	if cachedProgram, found := programCache.Get(exprString); found {
		prg := cachedProgram.(cel.Program)

		// Parse data as simple environment
		var env map[string]interface{}
		if dataString != "" {
			env = map[string]interface{}{
				"data": dataString,
				"len":  func(s string) int { return len(s) },
			}
		} else {
			env = map[string]interface{}{}
		}

		// Execute the expression
		out, _, err := prg.Eval(env)
		if err != nil {
			errorMsg := fmt.Sprintf("CEL evaluation error: %v", err)
			return C.CString(errorMsg)
		}

		// Convert result to string
		resultStr := fmt.Sprintf("%v", out)
		return C.CString(resultStr)
	}

	// Create CEL environment
	celEnv, err := createCELEnv()
	if err != nil {
		errorMsg := fmt.Sprintf("CEL environment creation error: %v", err)
		return C.CString(errorMsg)
	}

	// Compile the expression (cache miss)
	ast, issues := celEnv.Compile(exprString)
	if issues != nil && issues.Err() != nil {
		errorMsg := fmt.Sprintf("CEL compilation error: %v", issues.Err())
		return C.CString(errorMsg)
	}

	prg, err := celEnv.Program(ast)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL program creation error: %v", err)
		return C.CString(errorMsg)
	}

	// Cache the compiled program
	programCache.Set(exprString, prg, 1)

	// Parse data as simple environment
	var env map[string]interface{}
	if dataString != "" {
		env = map[string]interface{}{
			"data": dataString,
			"len":  func(s string) int { return len(s) },
		}
	} else {
		env = map[string]interface{}{}
	}

	// Execute the expression
	out, _, err := prg.Eval(env)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL evaluation error: %v", err)
		return C.CString(errorMsg)
	}

	// Convert result to string
	resultStr := fmt.Sprintf("%v", out)
	return C.CString(resultStr)
}

//export pg_cel_eval_json
func pg_cel_eval_json(expressionStr *C.char, jsonData *C.char) *C.char {
	// Convert C strings to Go strings
	exprString := C.GoString(expressionStr)
	jsonString := C.GoString(jsonData)

	// Try to get compiled program from cache
	var prg cel.Program
	if cachedProgram, found := programCache.Get(exprString); found {
		prg = cachedProgram.(cel.Program)
	} else {
		// Create CEL environment
		celEnv, err := createCELEnv()
		if err != nil {
			errorMsg := fmt.Sprintf("CEL environment creation error: %v", err)
			return C.CString(errorMsg)
		}

		// Compile the expression (cache miss)
		ast, issues := celEnv.Compile(exprString)
		if issues != nil && issues.Err() != nil {
			errorMsg := fmt.Sprintf("CEL compilation error: %v", issues.Err())
			return C.CString(errorMsg)
		}

		var err2 error
		prg, err2 = celEnv.Program(ast)
		if err2 != nil {
			errorMsg := fmt.Sprintf("CEL program creation error: %v", err2)
			return C.CString(errorMsg)
		}

		// Cache the compiled program
		programCache.Set(exprString, prg, 1)
	}

	// Parse JSON data with caching
	var env map[string]interface{}
	if jsonString != "" && jsonString != "{}" {
		// Try to get parsed JSON from cache
		if cachedEnv, found := jsonCache.Get(jsonString); found {
			env = cachedEnv.(map[string]interface{})
		} else {
			// Parse JSON (cache miss)
			env = make(map[string]interface{})
			err := json.Unmarshal([]byte(jsonString), &env)
			if err != nil {
				errorMsg := fmt.Sprintf("JSON parsing error: %v", err)
				return C.CString(errorMsg)
			}
			// Cache the parsed JSON with cost based on approximate size
			cost := int64(len(jsonString) / 100) // Rough cost estimation
			if cost < 1 {
				cost = 1
			}
			jsonCache.Set(jsonString, env, cost)
		}
	} else {
		env = map[string]interface{}{}
	}

	// Execute the expression
	out, _, err := prg.Eval(env)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL evaluation error: %v", err)
		return C.CString(errorMsg)
	}

	// Convert result to string
	resultStr := fmt.Sprintf("%v", out)
	return C.CString(resultStr)
}

//export pg_cel_compile_check
func pg_cel_compile_check(expressionStr *C.char) *C.char {
	// Convert C string to Go string
	exprString := C.GoString(expressionStr)

	// Create CEL environment
	celEnv, err := createCELEnv()
	if err != nil {
		errorMsg := fmt.Sprintf("CEL environment creation error: %v", err)
		return C.CString(errorMsg)
	}

	// Try to compile the expression
	_, issues := celEnv.Compile(exprString)
	if issues != nil && issues.Err() != nil {
		errorMsg := fmt.Sprintf("Invalid CEL expression: %v", issues.Err())
		return C.CString(errorMsg)
	}

	return C.CString("OK")
}

//export pg_cel_cache_stats
func pg_cel_cache_stats() *C.char {
	var stats map[string]interface{}

	if programCache != nil {
		programMetrics := programCache.Metrics
		stats = map[string]interface{}{
			"program_cache": map[string]interface{}{
				"hits":          programMetrics.Hits(),
				"misses":        programMetrics.Misses(),
				"cost_added":    programMetrics.CostAdded(),
				"cost_evicted":  programMetrics.CostEvicted(),
				"sets_dropped":  programMetrics.SetsDropped(),
				"sets_rejected": programMetrics.SetsRejected(),
				"gets_kept":     programMetrics.GetsKept(),
				"gets_dropped":  programMetrics.GetsDropped(),
			},
		}

		if jsonCache != nil {
			jsonMetrics := jsonCache.Metrics
			stats["json_cache"] = map[string]interface{}{
				"hits":          jsonMetrics.Hits(),
				"misses":        jsonMetrics.Misses(),
				"cost_added":    jsonMetrics.CostAdded(),
				"cost_evicted":  jsonMetrics.CostEvicted(),
				"sets_dropped":  jsonMetrics.SetsDropped(),
				"sets_rejected": jsonMetrics.SetsRejected(),
				"gets_kept":     jsonMetrics.GetsKept(),
				"gets_dropped":  jsonMetrics.GetsDropped(),
			}
		}
	}

	// Convert to JSON string
	jsonBytes, err := json.Marshal(stats)
	if err != nil {
		return C.CString(fmt.Sprintf("Error marshaling stats: %v", err))
	}

	return C.CString(string(jsonBytes))
}

//export pg_cel_cache_clear
func pg_cel_cache_clear() *C.char {
	if programCache != nil {
		programCache.Clear()
	}
	if jsonCache != nil {
		jsonCache.Clear()
	}
	return C.CString("Cache cleared successfully")
}

func main() {} // Required for CGO
