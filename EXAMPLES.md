# pg-cel Examples

This document provides examples of using the pg-cel PostgreSQL extension for Common Expression Language (CEL) evaluation.

## Basic Examples

### Simple Variable Access

```sql
SELECT cel_eval_json('name', '{"name": "World"}');
-- Returns: World
```

### String Operations

```sql
-- String concatenation
SELECT cel_eval_json('"Hello " + name', '{"name": "World"}');
-- Returns: Hello World

-- String manipulation
SELECT cel_eval_string('name.lowerAscii() + "@company.com"', '{"name": "JOHN"}');
-- Returns: john@company.com

-- String checks
SELECT cel_eval_bool('"hello@example.com".contains("@")', '{}');
-- Returns: true
```

### Numeric Operations

```sql
-- Arithmetic
SELECT cel_eval('2 + 3 * 4');
-- Returns: 14

-- Calculations with variables
SELECT cel_eval_numeric('price * (1.0 - discount)', '{"price": 100.0, "discount": 0.15}');
-- Returns: 85

-- Rounding
SELECT cel_eval_numeric('int(price * tax_rate + 0.5)', '{"price": 99.99, "tax_rate": 0.075}');
-- Returns: 7
```

### Boolean Logic

```sql
-- Simple conditions
SELECT cel_eval_bool('age >= 18.0 && verified', '{"age": 25.0, "verified": true}');
-- Returns: true

-- Ternary operator
SELECT cel_eval_json('age >= 21.0 ? "adult" : "minor"', '{"age": 25.0}');
-- Returns: adult
```

### List and Map Operations

```sql
-- List size
SELECT cel_eval_json('[1, 2, 3].size()', '{}');
-- Returns: 3

-- List filtering
SELECT cel_eval_json('[1, 2, 3, 4, 5].filter(x, x % 2 == 0)', '{}');
-- Returns: [2, 4]

-- Map access
SELECT cel_eval_json('user.name', '{"user": {"name": "Alice", "age": 30}}');
-- Returns: Alice
```

## Advanced Examples

### Complex Conditions

```sql
SELECT cel_eval_bool(
    'user.active && user.roles.exists(r, r == "admin") && user.last_login > timestamp("2024-01-01T00:00:00Z")',
    '{"user": {"active": true, "roles": ["user", "admin"], "last_login": "2024-07-01T10:00:00Z"}}'
);
```

### Using in WHERE Clauses

```sql
SELECT * FROM users
WHERE cel_eval_bool('age >= 18.0 && status == "active"', 
                   json_build_object('age', age, 'status', status));
```

### Dynamic Filtering

```sql
CREATE OR REPLACE FUNCTION filter_records(data jsonb, filter_expr text) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN cel_eval_bool(filter_expr, data::text);
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM products 
WHERE filter_records(
    jsonb_build_object('price', price, 'category', category, 'in_stock', in_stock),
    'price < 100.0 && (category == "electronics" || in_stock == true)'
);
```

## Performance Considerations

### Cache Management

```sql
-- View cache statistics
SELECT cel_cache_stats();

-- Clear cache if needed
SELECT cel_cache_clear();
```

### Configuration

Adjust cache sizes in postgresql.conf:

```
pg_cel.program_cache_size_mb = 256  # Default 256MB
pg_cel.json_cache_size_mb = 128     # Default 128MB
```


