# Troubleshooting

This document provides solutions for common issues when installing or using the pg-cel extension.

## Installation Issues

### Extension Files Not Found

If PostgreSQL reports that it cannot find the extension files, ensure they are copied to the correct directories:

```bash
# Find PostgreSQL directories
pg_config --pkglibdir    # Where to copy pg_cel.so/.dylib
pg_config --sharedir     # Where to find the extension/ subdirectory

# Check if files exist
ls -la $(pg_config --pkglibdir)/pg_cel.*
ls -la $(pg_config --sharedir)/extension/pg_cel*
```

### Library Loading Errors

If you see errors about missing libraries or undefined symbols:

1. Ensure you're using the correct binary for your PostgreSQL version
2. Check PostgreSQL logs for detailed error messages
3. Verify that all dependencies are installed:

```bash
# On Linux
ldd $(pg_config --pkglibdir)/pg_cel.so

# On macOS
otool -L $(pg_config --pkglibdir)/pg_cel.dylib
```

## Runtime Issues

### CEL Expression Errors

For CEL expression syntax errors:

1. Test simple expressions first: `SELECT cel_eval('1 + 2');`
2. Verify your JSON input format
3. Check CEL's [language syntax guide](https://github.com/google/cel-spec/blob/master/doc/langdef.md)

### Performance Issues

If you encounter performance issues:

1. Check cache statistics: `SELECT cel_cache_stats();`
2. Adjust cache sizes in postgresql.conf:
   ```
   pg_cel.program_cache_size_mb = 256  # Default 128MB
   pg_cel.json_cache_size_mb = 128     # Default 64MB
   ```
3. Restart PostgreSQL after changing configuration

## Getting Help

If you're still facing issues:

1. Open a [GitHub issue](https://github.com/SPANDigital/pg-cel/issues)
2. Include details about your environment (OS, PostgreSQL version, etc.)
3. Share error messages from PostgreSQL logs
