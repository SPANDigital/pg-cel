package main

import "C"

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"

	"github.com/dgraph-io/ristretto"
	"github.com/google/cel-go/cel"
	"github.com/google/cel-go/checker/decls"
	"github.com/google/cel-go/ext"
	exprpb "google.golang.org/genproto/googleapis/api/expr/v1alpha1"
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

// Helper function to determine CEL type from Go value
func getCELType(value interface{}) *exprpb.Type {
	switch value.(type) {
	case string:
		return decls.String
	case int, int32, int64:
		return decls.Int
	case float32, float64:
		return decls.Double
	case bool:
		return decls.Bool
	case []interface{}:
		return decls.NewListType(decls.Dyn)
	case map[string]interface{}:
		return decls.NewMapType(decls.String, decls.Dyn)
	default:
		return decls.Dyn
	}
}

// Helper function to create a cache key based on expression and JSON structure
func createCacheKey(expression string, jsonData map[string]interface{}) string {
	// Create a signature based on the JSON keys and their types
	var keyTypes []string
	for key, value := range jsonData {
		var typeStr string
		switch v := value.(type) {
		case string:
			typeStr = "string"
		case bool:
			typeStr = "bool"
		case float64:
			typeStr = "float64"
		case int, int32, int64, float32:
			typeStr = "number"
		case []interface{}:
			typeStr = "list"
		case map[string]interface{}:
			typeStr = "map"
			// For maps, include nested keys in the signature
			var nestedKeys []string
			for nk := range v {
				nestedKeys = append(nestedKeys, nk)
			}
			if len(nestedKeys) > 0 {
				typeStr += ":" + strings.Join(nestedKeys, ",")
			}
		default:
			typeStr = fmt.Sprintf("%T", v)
		}
		keyTypes = append(keyTypes, fmt.Sprintf("%s:%s", key, typeStr))
	}
	
	// Sort for consistency
	sort.Strings(keyTypes)
	signature := strings.Join(keyTypes, ";")
	
	// Create hash of expression + signature
	hasher := sha256.New()
	hasher.Write([]byte(expression + "|" + signature))
	return hex.EncodeToString(hasher.Sum(nil))
}

// Create a dynamic CEL environment with variables from JSON data
func createDynamicCELEnv(jsonData map[string]interface{}) (*cel.Env, error) {
	// Start with extensions
	opts := []cel.EnvOption{
		ext.Strings(),
		ext.Math(),
		ext.Lists(),
		ext.Bindings(),
		ext.Protos(),
		ext.Encoders(),
		ext.Sets(),
	}
	
	// Collect all variable declarations in a slice
	var declarations []*exprpb.Decl
	
	// Add variable declarations - IMPORTANT: we must declare all variables upfront
	for key, value := range jsonData {
		var t *exprpb.Type
		switch v := value.(type) {
		case string:
			t = decls.String
		case bool:
			t = decls.Bool
		case float64:
			// All JSON numbers are parsed as float64 by Go's json package
			t = decls.Double
		case int, int32, int64, float32:
			// These cases are unlikely with JSON but included for completeness
			t = decls.Double
		case []interface{}:
			t = decls.NewListType(decls.Dyn)
		case map[string]interface{}:
			t = decls.NewMapType(decls.String, decls.Dyn)
		default:
			fmt.Fprintf(os.Stderr, "DEBUG: Unknown type for %s: %T = %v\n", key, v, v)
			t = decls.Dyn
		}
		
		// Create a variable declaration
		declarations = append(declarations, decls.NewVar(key, t))
	}
	
	// Add all declarations at once (this is more efficient than adding them individually)
	if len(declarations) > 0 {
		opts = append(opts, cel.Declarations(declarations...))
	}
	
	return cel.NewEnv(opts...)
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

	// Parse JSON
	var data map[string]interface{}
	if err := json.Unmarshal([]byte(jsonString), &data); err != nil {
		errorMsg := fmt.Sprintf("JSON parsing error: %v", err)
		return C.CString(errorMsg)
	}
	
	// Try direct variable access for simple expressions (significantly faster)
	trimmedExpr := strings.TrimSpace(exprString)
	if val, ok := data[trimmedExpr]; ok {
		resultStr := fmt.Sprintf("%v", val)
		return C.CString(resultStr)
	}
	
	// Add references for nested fields (e.g., "user.name")
	enhancedData := addReferenceVars(data)
	
	// Check if we have a dotted path notation that we can resolve directly
	if strings.Contains(trimmedExpr, ".") && !strings.Contains(trimmedExpr, " ") {
		if val, ok := enhancedData[trimmedExpr]; ok {
			resultStr := fmt.Sprintf("%v", val)
			return C.CString(resultStr)
		}
	}
	
	// Create cache key for this expression + JSON structure
	cacheKey := createCacheKey(exprString, data)
	
	// Check if we have a cached program for this expression + variable structure
	if cachedProgram, found := programCache.Get(cacheKey); found {
		prg := cachedProgram.(cel.Program)
		
		// Execute the cached program with the JSON data
		out, _, err := prg.Eval(data)
		if err != nil {
			errorMsg := fmt.Sprintf("CEL evaluation error: %v", err)
			return C.CString(errorMsg)
		}
		
		// Convert result to string
		resultStr := fmt.Sprintf("%v", out)
		return C.CString(resultStr)
	}
	
	// Create a dynamic environment with all variables from the JSON
	celEnv, err := createDynamicCELEnv(data)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL environment creation error: %v", err)
		return C.CString(errorMsg)
	}

	// Compile the expression
	ast, issues := celEnv.Compile(exprString)
	if issues != nil && issues.Err() != nil {
		errorMsg := fmt.Sprintf("CEL compilation error: %v", issues.Err())
		return C.CString(errorMsg)
	}

	// Create the program
	prg, err := celEnv.Program(ast)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL program creation error: %v", err)
		return C.CString(errorMsg)
	}
	
	// Cache the compiled program with the unique key
	programCache.Set(cacheKey, prg, 1)

	// Execute the expression with the JSON data
	out, _, err := prg.Eval(data)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL evaluation error: %v", err)
		return C.CString(errorMsg)
	}

	// Convert result to string
	resultStr := fmt.Sprintf("%v", out)
	return C.CString(resultStr)
}

// Simple function to evaluate JavaScript-like string expressions
func evaluateJSLikeExpression(expr string) string {
	// Handle simple string concatenation like '"Hello" + " World"' or '"Hello" + "World"'
	parts := strings.Split(expr, "+")
	var result strings.Builder
	
	for _, part := range parts {
		// Trim spaces
		trimmed := strings.TrimSpace(part)
		
		// Remove quotes (both double and single)
		if strings.HasPrefix(trimmed, "\"") && strings.HasSuffix(trimmed, "\"") {
			trimmed = trimmed[1 : len(trimmed)-1]
		} else if strings.HasPrefix(trimmed, "'") && strings.HasSuffix(trimmed, "'") {
			trimmed = trimmed[1 : len(trimmed)-1]
		}
		
		result.WriteString(trimmed)
	}
	
	return result.String()
}

//export pg_cel_compile_check
func pg_cel_compile_check(expressionStr *C.char) *C.char {
	// Convert C string to Go string
	exprString := C.GoString(expressionStr)

	// Create a standard CEL environment with common extensions
	celEnv, err := createCELEnv()
	if err != nil {
		errorMsg := fmt.Sprintf("CEL environment creation error: %v", err)
		return C.CString(errorMsg)
	}

	// Try to compile the expression with standard environment (no variables)
	ast, issues := celEnv.Compile(exprString)
	if issues != nil && issues.Err() != nil {
		// If compilation fails, it might be due to undeclared variables
		// Let's create a generic environment with some common variable types for validation
		testData := map[string]interface{}{
			"name": "test",
			"age": 25.0,
			"verified": true,
			"price": 99.99,
			"items": []interface{}{1, 2, 3},
			"user": map[string]interface{}{
				"name": "user",
				"role": "admin",
			},
		}
		
		dynEnv, dynErr := createDynamicCELEnv(testData)
		if dynErr != nil {
			errorMsg := fmt.Sprintf("Invalid CEL expression: %v", issues.Err())
			return C.CString(errorMsg)
		}
		
		// Try again with test variables
		_, dynIssues := dynEnv.Compile(exprString)
		if dynIssues != nil && dynIssues.Err() != nil {
			errorMsg := fmt.Sprintf("Invalid CEL expression: %v", dynIssues.Err())
			return C.CString(errorMsg)
		}
		
		// Successfully compiled with test variables
		return C.CString("OK (with variable declarations)")
	}

	// Successfully compiled without variables
	_, err = celEnv.Program(ast)
	if err != nil {
		errorMsg := fmt.Sprintf("CEL program creation error: %v", err)
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

// Helper function to handle nested field references if direct variable access fails
func addReferenceVars(jsonData map[string]interface{}) map[string]interface{} {
	// Create a copy of the original data to avoid modifying it
	data := make(map[string]interface{})
	for k, v := range jsonData {
		data[k] = v
	}
	
	// For each top-level object, add a reference to it 
	// so that expressions like "user.name" work even if "user" is not declared
	for k, v := range jsonData {
		if obj, ok := v.(map[string]interface{}); ok {
			// For each nested field, add a reference in the form "parent.field"
			for nestedKey, nestedVal := range obj {
				fieldRef := fmt.Sprintf("%s.%s", k, nestedKey)
				data[fieldRef] = nestedVal
			}
		}
	}
	
	return data
}

func main() {} // Required for CGO
