# GitHub Copilot Instructions for pg-cel

## Project Overview

This is **pg-cel**, a PostgreSQL extension that integrates Google's CEL (Common Expression Language) with PostgreSQL. The extension allows evaluating CEL expressions directly within SQL queries with high-performance caching.

## Architecture

### Core Components

1. **Go Backend** (`main.go`): Implements CEL evaluation using CGO exports
2. **C Wrapper** (`pg_wrapper.c`): PostgreSQL C extension interface
3. **SQL Interface** (`pg_cel--1.0.sql`): PostgreSQL function definitions
4. **Build System**: Cross-platform Makefile + build.sh for Linux/macOS

### Key Technologies

- **Language**: Go (with CGO for PostgreSQL integration)
- **CEL Library**: `github.com/google/cel-go`
- **Caching**: Ristretto cache (`github.com/dgraph-io/ristretto`)
- **Hashing**: FNV (non-cryptographic, optimized for performance)
- **Target Platforms**: Linux, macOS (PostgreSQL 14, 15, 16, 17)

## Code Patterns & Conventions

### Function Naming

- **Exported CGO functions**: `pg_cel_*` (e.g., `pg_cel_eval`, `pg_cel_eval_json`)
- **Helper functions**: camelCase (e.g., `createCELEnv`, `createCacheKey`)
- **SQL functions**: `cel_*` (e.g., `cel_eval`, `cel_eval_bool`, `cel_cache_stats`)

### Error Handling

- Always return meaningful error messages via `C.CString(errorMsg)`
- Use `fmt.Sprintf` for error formatting
- Prefix errors with context (e.g., "CEL compilation error:", "JSON parsing error:")

### Performance Patterns

- **Dual Caching System**:
  - Program cache: Compiled CEL expressions
  - JSON cache: Parsed JSON data structures
- **Fast Paths**: Direct variable access before CEL compilation
- **Cache Keys**: Use FNV hash for performance, include expression + JSON structure signature

### CGO Integration

```go
//export function_name
func function_name(param *C.char) *C.char {
    // Convert C strings
    goString := C.GoString(param)
    
    // ... logic ...
    
    // Return C string
    return C.CString(result)
}
```

### Memory Management

- Use `C.CString()` for returning strings to PostgreSQL
- PostgreSQL handles memory cleanup for returned C strings
- Go garbage collector handles Go-side memory

## Key Functions

### Core Evaluation Functions

1. **`pg_cel_eval`**: Basic CEL evaluation with simple data environment
2. **`pg_cel_eval_json`**: Advanced CEL evaluation with full JSON support
3. **`pg_cel_compile_check`**: Expression validation without execution

### Cache Management

1. **`pg_cel_cache_stats`**: Returns cache performance metrics
2. **`pg_cel_cache_clear`**: Clears all caches
3. **`pg_init_caches`**: Initialize caches with configurable sizes

### Helper Functions

1. **`createCacheKey`**: Generate FNV hash-based cache keys
2. **`createDynamicCELEnv`**: Create CEL environment with JSON variables
3. **`addReferenceVars`**: Handle dotted notation (e.g., "user.name")

## Development Guidelines

### When Adding New Features

1. **Follow CGO export pattern** for PostgreSQL-facing functions
2. **Add corresponding C wrapper** in `pg_wrapper.c`
3. **Define SQL function** in `pg_cel--1.0.sql`
4. **Update tests** in `test.sql`
5. **Add examples** to `EXAMPLES.md`

### Performance Considerations

- Prefer direct lookups over CEL compilation when possible
- Use FNV hashing for cache keys (never cryptographic hashes)
- Cache compiled programs, not just results
- Include variable structure in cache keys for safety

### Error Messages

- Be specific about the error type and context
- Include the failing expression in compilation errors
- Provide hints for common mistakes (undeclared variables, syntax errors)

### Testing

- Test with various PostgreSQL versions (14, 15, 16, 17)
- Test on both Linux and macOS
- Include edge cases: empty JSON, complex nested structures, large expressions
- Verify cache behavior under load

## Build System

### Files

- **`Makefile`**: PostgreSQL extension build rules
- **`build.sh`**: Cross-platform build script with error checking
- **`.github/workflows/`**: CI/CD for multiple PostgreSQL versions and platforms

### Key Build Commands

```bash
./build.sh           # Build extension
./build.sh test      # Build, install, and test
./build.sh package   # Create distribution package
make clean           # Clean build artifacts
```

## Configuration

### Cache Settings (postgresql.conf)

```
pg_cel.program_cache_size_mb = 256  # Default 128MB
pg_cel.json_cache_size_mb = 128     # Default 64MB
```

### Environment Variables

- `PG_CONFIG`: Path to pg_config binary
- `GO_VERSION`: Go version for builds (default: 1.24)

## Common Patterns

### Modern Go Features

- Use `any` instead of `interface{}` for Go 1.24+ compatibility
- Leverage enhanced performance optimizations in Go 1.24
- Follow modern Go conventions and best practices

### Adding a New CEL Extension

1. Update `createCELEnv()` to include new `ext.*()` calls
2. Document the new functionality in `EXAMPLES.md`
3. Add test cases covering the new extension

### Optimizing for New Data Types

1. Add type detection in `getCELType()`
2. Update `createDynamicCELEnv()` variable declarations
3. Consider direct access patterns in `pg_cel_eval_json`

### Debugging Performance Issues

1. Check cache hit rates via `cel_cache_stats()`
2. Profile cache key generation (ensure FNV is used)
3. Verify program compilation isn't happening repeatedly
4. Check for memory leaks in long-running operations

## Documentation Standards

- **README.md**: High-level features and installation
- **INSTALL.md**: Detailed platform-specific installation
- **EXAMPLES.md**: Comprehensive usage examples
- **TROUBLESHOOTING.md**: Common issues and solutions

## Deployment

- Multi-platform builds via GitHub Actions
- Releases include binaries for Linux/macOS × PostgreSQL 14/15/16/17
- Version tags trigger automated builds and releases
