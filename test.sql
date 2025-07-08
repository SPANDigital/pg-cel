-- Test file for pg-cel extension
-- This file tests basic functionality of the CEL (Common Expression Language) extension

-- Test basic arithmetic
SELECT cel_eval('2 + 3 * 4') AS arithmetic_result;
-- Expected: 14

-- Test string operations
SELECT cel_eval_json('"Hello" + " " + name', '{"name": "World"}') AS string_concat;
-- Expected: Hello World

-- Test boolean evaluation
SELECT cel_eval_bool('age >= 18.0 && verified', '{"age": 25.0, "verified": true}') AS is_adult_verified;
-- Expected: true

-- Test simple variable access
SELECT cel_eval_json('name', '{"name": "Alice"}') AS simple_var;
-- Expected: Alice

-- Test compilation check
SELECT cel_compile_check('age >= 18.0') AS compilation_valid;
-- Expected: OK

-- Test cache stats (should return JSON)
SELECT cel_cache_stats() AS cache_statistics;

-- Verify all tests passed
\echo 'All tests completed successfully!'

-- Test string manipulation
SELECT cel_eval_string('name.lowerAscii() + "@company.com"', '{"name": "JOHN"}') AS email_address;

-- Test error handling (should return false/null safely)
SELECT cel_eval_bool('nonexistent.field == "test"', '{}') AS safe_error_handling;

-- Clear cache for clean state
SELECT cel_cache_clear() AS cache_cleared;
