# Configuring pg-cel Cache

This document explains how to configure the Ristretto cache settings for the pg-cel extension.

## Configuration Parameters

The extension provides two configurable parameters that can be set in your PostgreSQL configuration:

### `pg_cel.program_cache_size_mb`
- **Purpose**: Sets the maximum size of the CEL program compilation cache in megabytes
- **Default**: 128 MB
- **Range**: 64 MB to 8192 MB (8 GB)
- **Restart Required**: No (PGC_SUSET - can be changed by superuser)

### `pg_cel.json_cache_size_mb`
- **Purpose**: Sets the maximum size of the JSON parsing cache in megabytes
- **Default**: 64 MB
- **Range**: 32 MB to 4096 MB (4 GB)
- **Restart Required**: No (PGC_SUSET - can be changed by superuser)

## Configuration Methods

### 1. postgresql.conf

Add these lines to your `postgresql.conf` file:

```conf
# pg-cel cache configuration
pg_cel.program_cache_size_mb = 512     # 512MB for program cache
pg_cel.json_cache_size_mb = 256        # 256MB for JSON cache
```

### 2. Command Line Parameters

Start PostgreSQL with cache configuration:

```bash
postgres -c pg_cel.program_cache_size_mb=2048 -c pg_cel.json_cache_size_mb=1024
```

### 3. ALTER SYSTEM (PostgreSQL 9.4+)

```sql
-- Set cache sizes (requires restart)
ALTER SYSTEM SET pg_cel.program_cache_size_mb = 2048;
ALTER SYSTEM SET pg_cel.json_cache_size_mb = 1024;
SELECT pg_reload_conf();
-- Then restart PostgreSQL
```

## Cache Management Functions

The extension provides several functions for cache management:

### `cel_cache_stats()`
Returns detailed cache statistics in JSON format:

```sql
SELECT cel_cache_stats();
```

Example output:
```json
{
  "program_cache": {
    "hits": 150,
    "misses": 25,
    "cost_added": 25000,
    "cost_evicted": 0,
    "sets_dropped": 0,
    "sets_rejected": 0,
    "gets_kept": 150,
    "gets_dropped": 0
  },
  "json_cache": {
    "hits": 300,
    "misses": 50,
    "cost_added": 45000,
    "cost_evicted": 1000,
    "sets_dropped": 0,
    "sets_rejected": 0,
    "gets_kept": 300,
    "gets_dropped": 0
  }
}
```

### `cel_cache_clear()`
Clears both program and JSON caches:

```sql
SELECT cel_cache_clear();
```

## Sizing Guidelines

### Program Cache
- **Small workloads**: 64-256 MB
- **Medium workloads**: 512-1024 MB (default)
- **Large workloads**: 2048-4096 MB
- **Very large workloads**: 8192 MB (maximum)

### JSON Cache
- **Small workloads**: 32-128 MB
- **Medium workloads**: 256-512 MB (default)
- **Large workloads**: 1024-2048 MB
- **Very large workloads**: 4096 MB (maximum)

## Performance Considerations

### Cache Hit Ratio
Monitor cache hit ratios using `cel_cache_stats()`:

```sql
-- Calculate hit ratios
SELECT 
    jsonb_path_query_first(
        cel_cache_stats()::jsonb, 
        '$.program_cache.hits / ($.program_cache.hits + $.program_cache.misses)'
    ) AS program_hit_ratio,
    jsonb_path_query_first(
        cel_cache_stats()::jsonb, 
        '$.json_cache.hits / ($.json_cache.hits + $.json_cache.misses)'
    ) AS json_hit_ratio;
```

### Optimal Cache Sizes
- **Program cache**: Should be sized to hold all unique CEL expressions in your workload
- **JSON cache**: Should be sized based on the variety and size of JSON documents

### Memory Usage
- Total memory usage ≈ `program_cache_size_mb + json_cache_size_mb`
- Account for this in your PostgreSQL `shared_buffers` and system memory planning

## Troubleshooting

### High Cache Misses
- Increase cache size if you have available memory
- Check for too many unique expressions or JSON documents
- Consider normalizing your expressions to improve cache effectiveness

### Memory Pressure
- Reduce cache sizes if PostgreSQL is experiencing memory pressure
- Monitor `cost_evicted` in cache stats to see if caches are full

### Performance Issues
- Use `cel_cache_stats()` to monitor cache effectiveness
- Clear caches with `cel_cache_clear()` if needed
- Consider restarting PostgreSQL to reset cache configurations

## Example Monitoring Query

```sql
-- Monitor cache performance
WITH cache_stats AS (
    SELECT cel_cache_stats()::jsonb AS stats
),
parsed_stats AS (
    SELECT 
        stats->'program_cache'->>'hits' AS program_hits,
        stats->'program_cache'->>'misses' AS program_misses,
        stats->'json_cache'->>'hits' AS json_hits,
        stats->'json_cache'->>'misses' AS json_misses,
        stats->'program_cache'->>'cost_added' AS program_cost_added,
        stats->'json_cache'->>'cost_added' AS json_cost_added
    FROM cache_stats
)
SELECT 
    program_hits::bigint + program_misses::bigint AS program_total_requests,
    CASE 
        WHEN (program_hits::bigint + program_misses::bigint) > 0 
        THEN round(program_hits::numeric / (program_hits::bigint + program_misses::bigint) * 100, 2)
        ELSE 0 
    END AS program_hit_ratio_percent,
    json_hits::bigint + json_misses::bigint AS json_total_requests,
    CASE 
        WHEN (json_hits::bigint + json_misses::bigint) > 0 
        THEN round(json_hits::numeric / (json_hits::bigint + json_misses::bigint) * 100, 2)
        ELSE 0 
    END AS json_hit_ratio_percent,
    pg_size_pretty(program_cost_added::bigint) AS program_cache_size_used,
    pg_size_pretty(json_cost_added::bigint) AS json_cache_size_used
FROM parsed_stats;
```

This will help you monitor and optimize your cache configuration for optimal performance.
