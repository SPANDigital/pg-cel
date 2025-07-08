# Status Update

## Fixed Issues

- Added support for CEL variable references from JSON data
- Fixed type handling for numeric values
- Added proper caching for compiled programs with different variable structures
- Added direct variable access for simple expressions for better performance
- Added support for nested field references using dotted notation
- Enhanced the compile check function to support expressions with variable references
- Fixed all test cases in test.sql

## Usage Example

```sql
-- Simple variable access
SELECT cel_eval_json('name', '{"name": "World"}');

-- String concatenation with variables
SELECT cel_eval_json('"Hello " + name', '{"name": "World"}');

-- Numeric operations
SELECT cel_eval_numeric('price * (1.0 - discount)', '{"price": 100.0, "discount": 0.15}');

-- Conditional expression
SELECT cel_eval_json('age >= 21.0 ? "adult" : "minor"', '{"age": 25.0}');

-- Nested object access
SELECT cel_eval_json('user.name', '{"user": {"name": "Alice", "age": 30}}');
```

