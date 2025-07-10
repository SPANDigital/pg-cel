package main

import "C"

import (
	"encoding/json"
	"fmt"
	"log"
	"sort"

	"github.com/dgraph-io/ristretto/v2"
	"github.com/google/cel-go/cel"
	"github.com/google/cel-go/ext"
)

// Ristretto cache for compiled CEL programs
var programCache *ristretto.Cache[string, cel.Program]

// Ristretto cache for parsed JSON data
var jsonCache *ristretto.Cache[string, map[string]any]

// Initialize caches with configurable sizes
//
//export pg_init_caches
func pg_init_caches(programCacheMB int, jsonCacheMB int) {
	var err error

	// Convert MB to bytes
	programCacheSize := int64(programCacheMB) * 1024 * 1024
	jsonCacheSize := int64(jsonCacheMB) * 1024 * 1024

	// Initialize program cache
	programCache, err = ristretto.NewCache(&ristretto.Config[string, cel.Program]{
		NumCounters: 1e7,              // number of keys to track frequency of (10M)
		MaxCost:     programCacheSize, // maximum cost of cache (configurable)
		BufferItems: 64,               // number of keys per Get buffer
		Metrics:     true,             // Enable metrics tracking
	})
	if err != nil {
		log.Fatalf("Failed to create program cache: %v", err)
	}

	// Initialize JSON cache
	jsonCache, err = ristretto.NewCache(&ristretto.Config[string, map[string]any]{
		NumCounters: 1e6,           // number of keys to track frequency of (1M)
		MaxCost:     jsonCacheSize, // maximum cost of cache (configurable)
		BufferItems: 64,            // number of keys per Get buffer
		Metrics:     true,          // Enable metrics tracking
	})
	if err != nil {
		log.Fatalf("Failed to create JSON cache: %v", err)
	}
}

func init() {
	// Default initialization removed to avoid duplicate cache initialization
	// In PostgreSQL, pg_init_caches will be called with configured GUC values
	// For standalone usage, caches will be initialized on first use or manually
}

// ensureCachesInitialized ensures caches are initialized with default values if not already done
func ensureCachesInitialized() {
	if programCache == nil || jsonCache == nil {
		pg_init_caches(128, 64) // Default fallback values
	}
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
		// Enable optional types extension for some advanced functions
		cel.OptionalTypes(),
	)
}

// getCELType converts Go values to appropriate CEL types
func getCELType(value any) *cel.Type {
	switch value.(type) {
	case string:
		return cel.StringType
	case int, int32, int64:
		return cel.IntType
	case float32, float64:
		return cel.DoubleType
	case bool:
		return cel.BoolType
	case []any:
		return cel.ListType(cel.DynType)
	case map[string]any:
		return cel.MapType(cel.StringType, cel.DynType)
	case nil:
		return cel.NullType
	default:
		return cel.DynType
	}
}

// createDynamicCELEnv creates a CEL environment with JSON variables declared
func createDynamicCELEnv(jsonData map[string]any) (*cel.Env, error) {
	var envOpts []cel.EnvOption

	// Add JSON variables as CEL variables
	for key, value := range jsonData {
		celType := getCELType(value)
		envOpts = append(envOpts, cel.Variable(key, celType))
	}

	// Add extensions
	envOpts = append(envOpts,
		ext.Strings(),
		ext.Math(),
		ext.Lists(),
		ext.Bindings(),
		ext.Protos(),
		ext.Encoders(),
		ext.Sets(),
	)

	return cel.NewEnv(envOpts...)
}

// addReferenceVars handles dotted notation like "user.name" by adding reference variables
func addReferenceVars(envOpts []cel.EnvOption, jsonData map[string]any) []cel.EnvOption {
	// For nested objects, we need to add the top-level references
	for key, value := range jsonData {
		if nestedMap, ok := value.(map[string]any); ok {
			// Add the top-level object
			celType := getCELType(value)
			envOpts = append(envOpts, cel.Variable(key, celType))

			// Recursively handle nested objects if needed
			for _, nestedValue := range nestedMap {
				if _, ok := nestedValue.(map[string]any); ok {
					nestedCelType := getCELType(nestedValue)
					// We already have the parent, so this is implicit
					_ = nestedCelType
				}
			}
		}
	}
	return envOpts
}

// createCacheKey generates a cache key that includes both expression and JSON structure
func createCacheKey(expression string, jsonData map[string]any) string {
	// Simple approach: include the JSON keys in the cache key
	// This ensures different JSON structures get different compiled programs
	if len(jsonData) == 0 {
		return expression
	}

	// Create a deterministic key based on the JSON structure
	var keys []string
	for key := range jsonData {
		keys = append(keys, key)
	}

	// Sort keys for deterministic cache keys
	// Note: In production, you'd want to use a proper sorting algorithm
	sort.Strings(keys)
	keyStr := fmt.Sprintf("%v", keys)
	return fmt.Sprintf("%s|%s", expression, keyStr)
}

//export pg_cel_eval
func pg_cel_eval(expressionStr *C.char, dataStr *C.char) *C.char {
	// Ensure caches are initialized
	ensureCachesInitialized()

	// Convert C strings to Go strings
	exprString := C.GoString(expressionStr)
	dataString := C.GoString(dataStr)

	// Try to get compiled program from cache
	if cachedProgram, found := programCache.Get(exprString); found {
		compiledProgram := cachedProgram

		// Parse data as simple environment
		var env map[string]any
		if dataString != "" {
			env = map[string]any{
				"data": dataString,
				"len":  func(s string) int { return len(s) },
			}
		} else {
			env = map[string]any{}
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
	// Wait for cache operation to complete
	programCache.Wait()

	// Parse data as simple environment
	var env map[string]any
	if dataString != "" {
		env = map[string]any{
			"data": dataString,
			"len":  func(s string) int { return len(s) },
		}
	} else {
		env = map[string]any{}
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
	// Ensure caches are initialized
	ensureCachesInitialized()

	// Convert C strings to Go strings
	exprString := C.GoString(expressionStr)
	jsonString := C.GoString(jsonData)

	// Parse JSON data first to determine variable structure
	var env map[string]any
	if jsonString != "" && jsonString != "{}" {
		// Try to get parsed JSON from cache
		if cachedEnv, found := jsonCache.Get(jsonString); found {
			env = cachedEnv
		} else {
			// Parse JSON (cache miss)
			env = make(map[string]any)
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
			// Wait for cache operation to complete
			jsonCache.Wait()
		}
	} else {
		env = map[string]any{}
	}

	// Create cache key that includes JSON structure
	cacheKey := createCacheKey(exprString, env)

	// Try to get compiled program from cache
	var prg cel.Program
	if cachedProgram, found := programCache.Get(cacheKey); found {
		prg = cachedProgram
	} else {
		// Create dynamic CEL environment with JSON variables
		celEnv, err := createDynamicCELEnv(env)
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

		// Cache the compiled program with the composite key
		programCache.Set(cacheKey, prg, 1)
		// Wait for cache operation to complete
		programCache.Wait()
	}

	// Execute the expression with the parsed JSON environment
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
		return C.CString("false")
	}

	// Try to compile the expression
	_, issues := celEnv.Compile(exprString)
	if issues != nil && issues.Err() != nil {
		return C.CString("false")
	}

	return C.CString("true")
}

//export pg_cel_cache_stats
func pg_cel_cache_stats() *C.char {
	var stats map[string]any

	if programCache != nil {
		programMetrics := programCache.Metrics
		stats = map[string]any{
			"program_hits":          programMetrics.Hits(),
			"program_misses":        programMetrics.Misses(),
			"program_cost_added":    programMetrics.CostAdded(),
			"program_cost_evicted":  programMetrics.CostEvicted(),
			"program_sets_dropped":  programMetrics.SetsDropped(),
			"program_sets_rejected": programMetrics.SetsRejected(),
			"program_gets_kept":     programMetrics.GetsKept(),
			"program_gets_dropped":  programMetrics.GetsDropped(),
			"program_entries":       programMetrics.KeysAdded(), // Add missing entries count
		}

		if jsonCache != nil {
			jsonMetrics := jsonCache.Metrics
			stats["json_hits"] = jsonMetrics.Hits()
			stats["json_misses"] = jsonMetrics.Misses()
			stats["json_cost_added"] = jsonMetrics.CostAdded()
			stats["json_cost_evicted"] = jsonMetrics.CostEvicted()
			stats["json_sets_dropped"] = jsonMetrics.SetsDropped()
			stats["json_sets_rejected"] = jsonMetrics.SetsRejected()
			stats["json_gets_kept"] = jsonMetrics.GetsKept()
			stats["json_gets_dropped"] = jsonMetrics.GetsDropped()
			stats["json_entries"] = jsonMetrics.KeysAdded() // Add missing entries count
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
