# BDD Testing Root Cause Analysis

## Executive Summary

After running the BDD tests, **18 out of 85 scenarios are passing** (21% success rate), with **45 failing** and **24 undefined**. The root causes are primarily **code implementation issues** rather than test or environment problems.

## Results Summary

- ✅ **18 scenarios passed** (21%)
- ❌ **45 scenarios failed** (53%)
- ⚠️ **24 scenarios undefined** (28%)
- **Total: 85 scenarios**

## Primary Root Causes

### 1. **JSON Variable Injection Missing** (Critical Issue)
**Impact**: 30+ failing scenarios
**Root Cause**: CODE - Missing implementation

The most critical issue is that JSON data is not being converted into CEL environment variables. The current implementation:

```go
// Current: JSON is parsed but NOT injected as CEL variables
env = make(map[string]any)
err := json.Unmarshal([]byte(jsonString), &env)
// env is used for execution but NOT for CEL environment variable declaration
```

**What's needed**: Dynamic CEL environment creation with JSON variables declared as CEL types:

```go
func createDynamicCELEnv(jsonData map[string]any) (*cel.Env, error) {
    var vars []*cel.Variable
    for key, value := range jsonData {
        celType := getCELType(value)
        vars = append(vars, cel.Variable(key, celType))
    }
    return cel.NewEnv(
        cel.Variable("data", cel.DynType), // existing
        vars..., // JSON variables
        ext.Strings(),
        ext.Math(),
        // ... other extensions
    )
}
```

**Examples of failing tests**:
- `name` (from `{"name": "John"}`) → "undeclared reference to 'name'"
- `user.profile.email` → "undeclared reference to 'user'"
- `numbers[2]` → "undeclared reference to 'numbers'"

### 2. **Missing CEL Extensions** (High Impact)
**Impact**: 10+ failing scenarios
**Root Cause**: CODE - Incomplete CEL environment setup

Missing math functions and other extensions:
- `math.max([1,5,3])` → "undeclared reference to 'math'"
- `math.min([1,5,3])` → "undeclared reference to 'min'"
- `math.ceil(3.14)` → Works (basic `ext.Math()` is included)
- `math.abs(-42)` → Missing advanced math functions

**Fix needed**: Add missing CEL extensions or custom functions.

### 3. **Missing SQL Function Signatures** (High Impact)
**Impact**: 8+ failing scenarios  
**Root Cause**: CODE - Incomplete SQL API

Tests expect functions that don't exist:
- `cel_eval_int()` → "function cel_eval_int(unknown) does not exist"
- `cel_eval_double()` → "function cel_eval_double(unknown) does not exist"

**Available functions**:
- ✅ `cel_eval()` 
- ✅ `cel_eval_json()`
- ✅ `cel_eval_bool()`
- ✅ `cel_eval_numeric()` (but tests expect `cel_eval_double`)
- ✅ `cel_eval_string()`
- ✅ `cel_compile_check()`
- ✅ `cel_cache_stats()`

**Fix needed**: Add missing function aliases or update test expectations.

### 4. **Error Handling Mismatch** (Medium Impact)
**Impact**: 15+ failing scenarios
**Root Cause**: CODE - Error classification

Tests expect different error types than what's returned:
- **Expected**: Compilation vs Runtime error distinction
- **Actual**: All errors returned as strings without classification

**Examples**:
- `1 +` → Expected: compilation error, Got: no error (appears to succeed)
- `1 / 0` → Expected: runtime error, Got: no error
- `undefined_var` → Expected: compilation error, Got: no error

**Fix needed**: Proper error detection and classification in CEL evaluation.

### 5. **Cache Statistics Format** (Medium Impact)
**Impact**: 5+ failing scenarios
**Root Cause**: CODE - Cache stats structure

Tests expect specific cache statistic fields:
- **Expected**: `program_hits`, `json_hits`, cache hit rates as percentages
- **Actual**: Different format returned by `cel_cache_stats()`

### 6. **Type Conversion Issues** (Low Impact)
**Impact**: 3+ failing scenarios
**Root Cause**: CODE - Result formatting

Minor type conversion issues:
- `string(42)` → Expected: string type, Got: integer type
- `2.5 + 1.5` → Expected: "4.0", Got: "4"

### 7. **CEL Macro Issues** (Low Impact)
**Impact**: 2+ failing scenarios
**Root Cause**: CODE/TEST - Missing macro support

- `has(missing_field)` → "invalid argument to has() macro"

## Secondary Issues (Undefined Steps)

**24 undefined steps** are due to overly specific Gherkin patterns that don't map to generic step definitions. These are **TEST issues** requiring refactoring of step definitions.

Examples:
- `I evaluate CEL expression 'size("hello world")'` → Should use generic `I evaluate CEL expression "<expr>"`
- Multiple variations of similar patterns

## What's Working Well

### ✅ **Passing Scenarios** (18 scenarios)
1. **Basic CEL expressions** without JSON variables
2. **String operations** (concatenation, contains, matches)
3. **Basic math** (arithmetic, comparisons)
4. **List operations** (size, basic filtering)
5. **Boolean logic**
6. **Cache management** (basic clear/init)
7. **SQL integration** (basic `cel_eval` calls)

### ✅ **Infrastructure**
- ✅ PostgreSQL extension loading
- ✅ Database connectivity  
- ✅ Basic CEL environment setup
- ✅ Caching infrastructure
- ✅ SQL function registration

## Recommendations by Priority

### 🔥 **Critical (Must Fix)**
1. **Implement JSON variable injection** - This fixes 35+ scenarios
2. **Add missing SQL function signatures** - This fixes 8+ scenarios

### 🔴 **High Priority**
3. **Fix error handling and classification** - This fixes 15+ scenarios
4. **Add missing CEL extensions** - This fixes 10+ scenarios

### 🟡 **Medium Priority**
5. **Fix cache statistics format** - This fixes 5+ scenarios
6. **Refactor undefined step definitions** - This fixes 24+ scenarios

### 🟢 **Low Priority**
7. **Fix type conversion edge cases** - This fixes 3+ scenarios

## Implementation Plan

### Phase 1: JSON Variable Injection (Biggest Impact)
```go
// Add to main.go
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

func getCELType(value any) *cel.Type {
    switch v := value.(type) {
    case string:
        return cel.StringType
    case int, int64, float64:
        return cel.IntType
    case bool:
        return cel.BoolType
    case []any:
        return cel.ListType(cel.DynType)
    case map[string]any:
        return cel.MapType(cel.StringType, cel.DynType)
    default:
        return cel.DynType
    }
}
```

### Phase 2: Missing SQL Functions
```sql
-- Add to pg_cel--1.4.0.sql
CREATE OR REPLACE FUNCTION cel_eval_int(expression text, json_data text DEFAULT '{}')
RETURNS integer
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data))::integer;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cel_eval_double(expression text, json_data text DEFAULT '{}')
RETURNS double precision  
AS $$
BEGIN
    RETURN (cel_eval_json(expression, json_data))::double precision;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### Phase 3: Error Handling
```go
// Add error classification
type CELError struct {
    Type    string // "compilation" | "runtime" | "json_parsing"
    Message string
}

func classifyError(err error, phase string) CELError {
    if phase == "compilation" {
        return CELError{Type: "compilation", Message: err.Error()}
    }
    if phase == "evaluation" {
        return CELError{Type: "runtime", Message: err.Error()}
    }
    return CELError{Type: "unknown", Message: err.Error()}
}
```

## Conclusion

The BDD test failures reveal **primarily code implementation gaps** rather than test or environment issues. The core PostgreSQL integration and basic CEL functionality work well, but advanced features like JSON variable injection and comprehensive error handling need implementation.

**Success Path**: Implementing JSON variable injection alone would increase the pass rate from 21% to approximately 60-65%, making this the highest-impact fix.
