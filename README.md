# pg-cel
PostgreSQL Extension for CEL (Common Expression Language) Evaluation

This extension allows you to evaluate [Google's CEL (Common Expression Language)](https://github.com/google/cel-spec) expressions directly within PostgreSQL, enabling powerful dynamic filtering, calculations, and data processing capabilities with Google's fast, portable, and secure expression evaluation language.

## Features

- Evaluate CEL expressions as PostgreSQL functions
- Support for JSON data input with full CEL syntax
- **High-performance dual caching system** using [Ristretto](https://github.com/dgraph-io/ristretto)
  - CEL program compilation caching (configurable, default 128MB)
  - JSON parsing caching (configurable, default 64MB)
  - Runtime cache statistics and management
- Type-safe convenience functions for boolean, numeric, and string results
- Expression validation and compilation checking
- Thread-safe concurrent operations optimized for PostgreSQL
- **Configurable cache sizes** via PostgreSQL configuration parameters
- Full CEL language support including:
  - Arithmetic, comparison, and logical operators
  - String operations and regex matching
  - List and map operations with comprehensions
  - Duration and timestamp handling
  - Mathematical functions
  - Protocol buffer support

## Platform Support

- **Linux (Ubuntu)**: ✅ Full support for PostgreSQL 14, 15, 16, 17
- **macOS**: ✅ Full support for PostgreSQL 14, 15, 16, 17
- **Windows**: ❌ Not currently supported

## Installation

For pre-built binaries, please download from the [GitHub Releases](https://github.com/SPANDigital/pg-cel/releases) page. Choose the appropriate package for your platform and PostgreSQL version.

### From Binaries

1. Download the appropriate package for your platform and PostgreSQL version
2. Extract the package: `tar -xzf pg-cel-[platform]-pg[version].tar.gz`
3. Copy files to PostgreSQL directories (requires admin privileges):
   ```bash
   # For Linux
   sudo cp pg_cel.so $(pg_config --pkglibdir)/
   sudo cp pg_cel.control $(pg_config --sharedir)/extension/
   sudo cp pg_cel--*.sql $(pg_config --sharedir)/extension/
   
   # For macOS
   sudo cp pg_cel.dylib $(pg_config --pkglibdir)/
   sudo cp pg_cel.control $(pg_config --sharedir)/extension/
   sudo cp pg_cel--*.sql $(pg_config --sharedir)/extension/
   ```
4. In PostgreSQL: `CREATE EXTENSION pg_cel;`

### From Source

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

## Functions

### Core Functions

- `cel_eval(expression text, data text DEFAULT '')` - Evaluate CEL expression with simple string data
- `cel_eval_json(expression text, json_data text DEFAULT '{}')` - Evaluate CEL expression with JSON data
- `cel_compile_check(expression text)` - Validate CEL expression syntax

### Convenience Functions

- `cel_eval_bool(expression text, json_data text DEFAULT '{}')` - Returns boolean result
- `cel_eval_numeric(expression text, json_data text DEFAULT '{}')` - Returns numeric result
- `cel_eval_string(expression text, json_data text DEFAULT '{}')` - Returns string result

### Cache Management Functions

- `cel_cache_stats()` - Get detailed cache performance statistics
- `cel_cache_clear()` - Clear both program and JSON caches

## Usage Examples

### Basic Math and Logic
```sql
SELECT cel_eval('2 + 3 * 4') AS result; -- Returns: 14
SELECT cel_eval('true && false') AS logical; -- Returns: false
```

### Working with JSON Data
```sql
SELECT cel_eval_bool('age >= 18 && verified', '{"age": 25, "verified": true}') AS is_eligible;
SELECT cel_eval_string('name + "@company.com"', '{"name": "john"}') AS email;
```

### String Operations
```sql
SELECT cel_eval_bool('"user@example.com".contains("@")', '{}') AS is_email_format;
SELECT cel_eval_json('"HELLO".lowerAscii()', '{}') AS lowercase; -- Returns: hello
```

### List and Map Operations
```sql
-- Filter and transform lists
SELECT cel_eval_json('[1, 2, 3, 4, 5].filter(x, x % 2 == 0)', '{}') AS even_numbers;
SELECT cel_eval_json('[1, 2, 3].map(x, x * 2)', '{}') AS doubled;

-- Map access
SELECT cel_eval_json('user.name', '{"user": {"name": "Alice", "age": 30}}') AS user_name;
```

### Complex Filtering
```sql
-- Filter products based on dynamic criteria
SELECT * FROM products 
WHERE cel_eval_bool('price > min_price && category in categories', 
                    jsonb_build_object('price', price, 'category', category, 
                                     'min_price', 100, 'categories', '["Electronics", "Books"]')::text);
```

### Duration and Time Operations
```sql
SELECT cel_eval_json('duration("1h").getSeconds()', '{}') AS hour_seconds; -- Returns: 3600
SELECT cel_eval_bool('timestamp("2024-07-08T10:00:00Z") > timestamp("2024-01-01T00:00:00Z")', '{}') AS is_after;
```

### Mathematical Functions
```sql
SELECT cel_eval_numeric('math.ceil(price * 1.075)', '{"price": 99.99}') AS price_with_tax;
SELECT cel_eval_numeric('math.abs(-42.5)', '{}') AS absolute_value;
```

## CEL Language Features

The extension supports the full CEL syntax including:

- **Arithmetic operations**: `+`, `-`, `*`, `/`, `%`
- **Comparison operators**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Logical operators**: `&&`, `||`, `!`
- **String operations**: `+` (concatenation), `contains()`, `startsWith()`, `endsWith()`, `matches()`
- **List operations**: `size()`, `in`, indexing `[0]`, `filter()`, `map()`, `all()`, `exists()`, `exists_one()`
- **Map operations**: key access, `size()`, `in`, `all()`, `exists()`
- **Conditional expressions**: `condition ? value_if_true : value_if_false`
- **Duration and timestamp**: `duration()`, `timestamp()`, time arithmetic
- **Mathematical functions**: `math.ceil()`, `math.floor()`, `math.round()`, `math.abs()`
- **Type functions**: `type()`, `string()`, `int()`, `double()`, `bool()`

## Configuration

### Cache Configuration

The extension supports configurable cache sizes via PostgreSQL configuration parameters:

```conf
# postgresql.conf
pg_cel.program_cache_size_mb = 512     # CEL program cache size (default: 128MB)
pg_cel.json_cache_size_mb = 256        # JSON cache size (default: 64MB)
```

### Cache Monitoring

```sql
-- View cache statistics
SELECT cel_cache_stats();

-- Clear caches if needed
SELECT cel_cache_clear();
```

## Performance Architecture

### Dual Caching System

The extension uses two separate high-performance Ristretto caches:

#### CEL Program Compilation Cache
- **Purpose**: Cache compiled CEL programs
- **Key**: Expression string (e.g., `'age >= 18 && verified'`)
- **Value**: Compiled CEL program object
- **Benefit**: Eliminates expensive expression compilation on repeated use

#### JSON Parsing Cache
- **Purpose**: Cache parsed JSON objects
- **Key**: Raw JSON string (e.g., `'{"age": 25, "verified": true}'`)
- **Value**: Parsed map[string]any object
- **Benefit**: Eliminates expensive JSON parsing for repeated JSON structures

### Performance Characteristics

- **Lock-free operations**: Uses Ristretto's concurrent algorithms
- **Smart eviction**: TinyLFU algorithm keeps frequently-used items
- **Cost-based management**: Automatic memory management based on usage patterns
- **Thread-safe**: Optimized for PostgreSQL's multi-connection environment

## Performance Notes

- **Expression caching**: CEL expressions are compiled once and cached indefinitely until evicted
- **JSON caching**: Complex JSON objects are parsed once and reused across different expressions
- **Memory efficiency**: Automatic eviction prevents memory bloat while maintaining performance
- **High concurrency**: Lock-free design scales perfectly with PostgreSQL connection pools
- **Cost optimization**: Larger JSON objects receive appropriate cache costs for balanced memory usage

Use `cel_compile_check()` to validate expressions before using them in production queries.

## Error Handling

The extension provides robust error handling:

- Invalid CEL expressions return error messages with details
- JSON parsing errors are clearly reported
- Type conversion functions (`cel_eval_bool`, `cel_eval_numeric`) return safe defaults on errors
- Cache operations are designed to gracefully handle memory pressure

## Examples of CEL vs SQL

| Task | SQL | CEL |
|------|-----|-----|
| Age check | `age >= 18` | `age >= 18` |
| String contains | `email LIKE '%@%'` | `email.contains("@")` |
| List filtering | Complex subquery | `items.filter(x, x.price > 100)` |
| Conditional logic | `CASE WHEN ... END` | `condition ? value1 : value2` |
| JSON path | `json_data->>'field'` | `json_data.field` |

## Development and CI/CD

### GitHub Actions

The project includes comprehensive CI/CD pipelines:

- **Continuous Integration**: Automatic testing on every push and pull request
- **Multi-platform builds**: Supports Linux and macOS with PostgreSQL 14-17
- **Automated releases**: Tagged releases trigger automatic builds and GitHub releases

### Release Process

To create a new release:

```bash
# Create and push a new release
./release.sh 1.0.0
```

This will:
1. Update version numbers
2. Run tests
3. Create and push a git tag
4. Trigger GitHub Actions to build and release packages

### Build Status

![CI](https://github.com/SPANDigital/pg-cel/workflows/CI/badge.svg)
![Build and Release](https://github.com/SPANDigital/pg-cel/workflows/Build%20and%20Release/badge.svg)

## Building

```bash
./build.sh deps    # Check dependencies and download modules
./build.sh build   # Build the extension
./build.sh install # Install the extension
./build.sh test    # Run tests
./build.sh clean   # Clean build artifacts
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
