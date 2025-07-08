-- Test file for pg-cel extension
-- This file tests basic functionality of the CEL (Common Expression Language) extension

-- Test basic arithmetic
SELECT cel_eval('2 + 3 * 4') AS arithmetic_result;

-- Test string operations
SELECT cel_eval_json('"Hello" + " " + name', '{"name": "World"}') AS string_concat;

-- Test boolean evaluation
SELECT cel_eval_bool('age >= 18.0 && verified', '{"age": 25.0, "verified": true}') AS is_adult_verified;

-- Test numeric evaluation with floating point
SELECT cel_eval_numeric('price * (1.0 - discount)', '{"price": 100.0, "discount": 0.15}') AS discounted_price;

-- Test list operations
SELECT cel_eval_json('[1, 2, 3].size()', '{}') AS list_size;

-- Test map access
SELECT cel_eval_json('user.name', '{"user": {"name": "Alice", "age": 30}}') AS user_name;

-- Test conditional expression
SELECT cel_eval_json('age >= 21.0 ? "adult" : "minor"', '{"age": 25.0}') AS age_category;

-- Test string functions
SELECT cel_eval_bool('"hello@example.com".contains("@")', '{}') AS is_email;

-- Test duration and timestamp (CEL built-ins)
SELECT cel_eval_json('duration("1h").getSeconds()', '{}') AS hour_in_seconds;

-- Test array filtering
SELECT cel_eval_json('[1, 2, 3, 4, 5].filter(x, x % 2 == 0)', '{}') AS even_numbers;

-- Test compilation check
SELECT cel_compile_check('age >= 18.0 && name.startsWith("A")') AS compilation_valid;

-- Test invalid compilation
SELECT cel_compile_check('invalid..syntax') AS compilation_invalid;

-- Test cache stats
SELECT cel_cache_stats() AS cache_statistics;

-- Test with complex JSON data
SELECT cel_eval_bool(
    'user.active && user.roles.exists(r, r == "admin") && user.last_login > timestamp("2024-01-01T00:00:00Z")',
    '{"user": {"active": true, "roles": ["user", "admin"], "last_login": "2024-07-01T10:00:00Z"}}'
) AS is_active_admin;

-- Test mathematical functions
SELECT cel_eval_numeric('int(price * tax_rate + 0.5)', '{"price": 99.99, "tax_rate": 0.075}') AS tax_amount;

-- Test string manipulation
SELECT cel_eval_string('name.lowerAscii() + "@company.com"', '{"name": "JOHN"}') AS email_address;

-- Test error handling (should return false/null safely)
SELECT cel_eval_bool('nonexistent.field == "test"', '{}') AS safe_error_handling;

-- Clear cache for clean state
SELECT cel_cache_clear() AS cache_cleared;
