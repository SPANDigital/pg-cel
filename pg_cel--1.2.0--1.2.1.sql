-- Update script from version 1.2.0 to 1.2.1
-- This script contains the changes needed to upgrade pg_cel from 1.2.0 to 1.2.1

-- Set secure search path for the upgrade
SET search_path = pg_catalog, pg_temp;

-- Version 1.2.1 improvements: Fix duplicate cache initialization
-- 
-- This version fixes an issue where cache initialization was called twice:
-- 1. In Go init() function (standalone usage)
-- 2. In PostgreSQL _PG_init() (PostgreSQL usage)
--
-- The fix removes the redundant call in Go init() so that only the PostgreSQL
-- initialization with configured GUC values is used.
--
-- No functional changes to SQL interface - this is purely an internal optimization.

-- No SQL changes needed - fix is in Go/C code
