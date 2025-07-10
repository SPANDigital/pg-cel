-- Update script from version 1.2.1 to 1.3.0
-- This script contains the changes needed to upgrade pg_cel from 1.2.1 to 1.3.0

-- Version 1.3.0 changes:
-- - Fixed macOS CI/CD build failures that were silently masked
-- - Improved GitHub Actions workflow reliability
-- - Synchronized extension version with release tags
-- - Enhanced build verification and error reporting

-- No database schema changes in this version
-- Extension functions remain unchanged

-- Clear cache as a precaution during upgrade
SELECT cel_cache_clear();
