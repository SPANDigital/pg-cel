-- Update script from version 1.0.7 to 1.1.0
-- This script contains the changes needed to upgrade pg_cel from 1.0.7 to 1.1.0

-- Set secure search path for the upgrade
SET search_path = pg_catalog, pg_temp;

-- Version 1.1.0 improvements:
-- Note: The functions in 1.0.7 are already optimally configured with proper IMMUTABLE/VOLATILE attributes
-- This upgrade serves as a template for future function optimizations

-- Example of how to update function attributes in future versions:
-- If we needed to add PARALLEL SAFE (not needed for pg-cel currently):
-- CREATE OR REPLACE FUNCTION cel_eval(expression text, data text DEFAULT '')
-- RETURNS text
-- AS 'MODULE_PATHNAME', 'cel_eval_pg'
-- LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

-- For now, this upgrade is minimal as 1.0.7 functions are already optimized
-- Future versions could add:
-- - New CEL extension functions
-- - Performance improvements  
-- - Additional convenience functions
