-- Update script from version 1.1.0 to 1.2.0
-- This script contains the changes needed to upgrade pg_cel from 1.1.0 to 1.2.0

-- Set secure search path for the upgrade
SET search_path = pg_catalog, pg_temp;

-- Version 1.2.0 improvements: Halve cache sizes for improved memory efficiency
-- 
-- This version reduces the default cache sizes to optimize memory usage:
-- - Program cache: 256MB → 128MB (halved) 
-- - JSON cache: 128MB → 64MB (halved)
--
-- Changes are implemented in the Go code initialization and C wrapper defaults.
-- Users can still override these values using postgresql.conf parameters:
-- - pg_cel.program_cache_size_mb (default now 128MB)
-- - pg_cel.json_cache_size_mb (default now 64MB)

-- Clear existing caches to ensure new cache sizes take effect on next initialization
-- Note: This is optional and safe - caches will be recreated with new sizes on next use
DO $$
BEGIN
    -- Clear caches if the function exists (defensive programming)
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'cel_cache_clear' AND pronargs = 0) THEN
        PERFORM public.cel_cache_clear();
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- If clearing cache fails, that's OK - new cache sizes will take effect anyway
        NULL;
END
$$;

-- No SQL function changes needed - cache size reduction is handled in Go/C code
