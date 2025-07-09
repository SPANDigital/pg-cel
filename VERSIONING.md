# PostgreSQL Extension Versioning Guide

This document explains how `pg-cel` handles versioning following PostgreSQL extension best practices and semantic versioning.

## Overview

The `pg-cel` extension uses **semantic versioning** (MAJOR.MINOR.PATCH) and supports PostgreSQL's built-in extension upgrade mechanism. This allows users to easily upgrade between extension versions while maintaining data integrity.

## Versioning Strategy

### Extension Version vs. Release Version

- **Extension Version**: Used by PostgreSQL's extension system (e.g., `1.0.6`, `1.1.0`, `2.0.0`)
- **Release Version**: Git tags for software releases (e.g., `v1.0.6`, `v1.0.7`)

**Important**: As of v1.0.6, extension versions are synchronized with release versions. This means:
- Release v1.0.6 = Extension 1.0.6
- Release v1.1.0 = Extension 1.1.0  
- etc.

The extension version changes when the SQL interface or functionality changes. Release versions track all software updates, and we maintain 1:1 alignment for clarity.

### Current Structure

```
pg_cel.control              # Main control file (default_version = '1.0.7')

# Installation Scripts (base versions for direct install)
pg_cel--1.0.0.sql          # Base installation script for version 1.0.0  
pg_cel--1.0.6.sql          # Installation script for version 1.0.6
pg_cel--1.0.7.sql          # Current version installation script

# Upgrade Scripts (version transitions)
pg_cel--1.0.0--1.0.6.sql   # Upgrade script from 1.0.0 to 1.0.6
pg_cel--1.0.6--1.0.7.sql   # Upgrade script from 1.0.6 to 1.0.7
pg_cel--1.0.7--1.1.0.sql   # Future upgrade script (created when needed)
```

The Makefile organizes these files into logical groups:
- `INSTALL_SCRIPTS`: Base installation scripts for each version
- `UPGRADE_SCRIPTS`: Version transition scripts  
- `DATA`: Combined list for PostgreSQL installation

## Version Management

### Using the `manage_version.sh` Script

The repository includes a script to automate version management:

```bash
# Show current version status with organized file listing
./manage_version.sh status

# Bump patch version (1.0.7 → 1.0.8)
./manage_version.sh bump patch

# Bump minor version (1.0.7 → 1.1.0)
./manage_version.sh bump minor

# Bump major version (1.0.7 → 2.0.0)
./manage_version.sh bump major

# Clean up old versions (keep latest 3 versions)
./manage_version.sh cleanup

# Keep only latest 2 versions
./manage_version.sh cleanup 2
```

### What the Script Does

1. **Creates upgrade script**: Generates `pg_cel--old_version--new_version.sql`
2. **Updates control file**: Sets new `default_version` in `pg_cel.control`
3. **Updates Makefile**: Organizes SQL files into INSTALL_SCRIPTS and UPGRADE_SCRIPTS
4. **Provides guidance**: Shows next steps for testing and release
5. **Cleanup support**: Can remove old versions to keep file structure manageable

## Extension Upgrade Process

### For Users

Once installed, users can upgrade the extension using PostgreSQL's built-in commands:

```sql
-- Check current version
SELECT extversion FROM pg_extension WHERE extname = 'pg_cel';

-- Upgrade to latest version
ALTER EXTENSION pg_cel UPDATE;

-- Upgrade to specific version
ALTER EXTENSION pg_cel UPDATE TO '1.1.0';

-- Check available upgrade paths
SELECT * FROM pg_extension_update_paths('pg_cel');
```

### For Developers

When creating a new version:

1. **Run version bump**:
   ```bash
   ./manage_version.sh bump minor  # or patch/major
   ```

2. **Edit the upgrade script**:
   ```bash
   # Edit the generated pg_cel--old--new.sql file
   vim pg_cel--1.0.0--1.1.0.sql
   ```

3. **Add upgrade logic** (examples):
   ```sql
   -- Add new function
   CREATE OR REPLACE FUNCTION cel_eval_array(expression text, json_data text DEFAULT '{}')
   RETURNS json
   AS 'MODULE_PATHNAME', 'cel_eval_array_pg'
   LANGUAGE C STRICT;

   -- Modify existing function
   CREATE OR REPLACE FUNCTION cel_eval_bool(expression text, json_data text DEFAULT '{}')
   RETURNS boolean
   AS $$
   BEGIN
       -- Enhanced implementation
       RETURN (cel_eval_json(expression, json_data))::boolean;
   EXCEPTION
       WHEN OTHERS THEN
           RETURN false;
   END;
   $$ LANGUAGE plpgsql STRICT IMMUTABLE
   SET search_path = pg_catalog, pg_temp;
   ```

4. **Test the upgrade**:
   ```bash
   make install
   psql -d test_db -c "ALTER EXTENSION pg_cel UPDATE TO '1.1.0';"
   ```

5. **Commit and tag**:
   ```bash
   git add .
   git commit -m "Add version 1.1.0 with array support"
   git tag v1.1.0
   git push && git push --tags
   ```

## Version Examples

### Patch Version (1.0.0 → 1.0.1)
- Bug fixes in existing functions
- Documentation improvements
- Internal code optimizations
- No API changes

### Minor Version (1.0.0 → 1.1.0)
- New functions or features
- New convenience functions
- Backward-compatible enhancements
- Optional new parameters

### Major Version (1.0.0 → 2.0.0)
- Breaking API changes
- Function signature changes
- Removed deprecated functions
- Major architectural changes

## Best Practices

### Security in Upgrade Scripts

Always set secure search path in upgrade scripts:

```sql
-- At the top of every upgrade script
SET search_path = pg_catalog, pg_temp;

-- Your upgrade logic here...
```

### Testing Upgrades

Test upgrade paths thoroughly:

```bash
# Install base version
psql -d test_db -c "CREATE EXTENSION pg_cel VERSION '1.0.0';"

# Test upgrade
psql -d test_db -c "ALTER EXTENSION pg_cel UPDATE TO '1.1.0';"

# Verify functionality
psql -d test_db -f test.sql
```

### Avoiding Complex Upgrade Paths

Keep upgrade paths simple:
- Prefer direct upgrades (1.0.0 → 1.1.0)
- Avoid creating complex chains (1.0.0 → 1.0.1 → 1.1.0)
- Use semantic versioning to communicate changes clearly

## File Structure Reference

```
pg-cel/
├── pg_cel.control                 # Extension metadata
├── pg_cel--1.0.0.sql             # Base installation (version 1.0.0)
├── pg_cel--1.0.0--1.1.0.sql      # Upgrade 1.0.0 → 1.1.0
├── pg_cel--1.1.0--1.2.0.sql      # Upgrade 1.1.0 → 1.2.0
├── manage_version.sh              # Version management tool
└── Makefile                       # Build configuration
```

## Troubleshooting

### Extension Won't Upgrade

```sql
-- Check current version
SELECT extversion FROM pg_extension WHERE extname = 'pg_cel';

-- Check available versions
SELECT * FROM pg_available_extension_versions WHERE name = 'pg_cel';

-- Check upgrade paths
SELECT * FROM pg_extension_update_paths('pg_cel');
```

### Missing Upgrade Script

If you see "extension ... has no update path from version ...", you need to create the appropriate upgrade script:

```bash
# Create missing upgrade script manually
touch pg_cel--old_version--new_version.sql
# Add appropriate SQL commands
```

### Version Mismatch

If the control file version doesn't match installed version:

1. Check `pg_cel.control` has correct `default_version`
2. Ensure all SQL files are installed in the extension directory
3. Restart PostgreSQL if needed

This versioning system ensures that `pg-cel` can be safely upgraded across versions while maintaining PostgreSQL extension best practices.
