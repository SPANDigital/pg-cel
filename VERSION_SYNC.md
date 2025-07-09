# Extension Version Synchronization

This document explains how we resolved the version mismatch between release tags and PostgreSQL extension versions in pg-cel.

## The Problem

- **Release tags**: Up to v1.0.6 (tracking all software changes)
- **Extension version**: Started at 1.0.0 (using semantic versioning)
- **Result**: Confusion between software releases and extension versions

## The Solution

We synchronized the extension version to match the current release tag by:

1. **Creating version 1.0.6 extension files**:
   - `pg_cel--1.0.6.sql` (identical to 1.0.0, no SQL changes)
   - `pg_cel--1.0.0--1.0.6.sql` (upgrade script)

2. **Updated control file**: `default_version = '1.0.6'`

3. **Maintained backward compatibility**: Users can still install version 1.0.0 and upgrade

## Version Alignment Strategy

Going forward, we maintain alignment between release tags and extension versions:

- **Release v1.0.6** = **Extension 1.0.6** ✅
- **Release v1.0.7** = **Extension 1.0.7** (when SQL changes occur)
- **Release v1.1.0** = **Extension 1.1.0** (minor feature additions)

## Why This Approach?

1. **User Clarity**: Extension version matches release version they download
2. **Semantic Meaning**: Extension version reflects actual functionality
3. **PostgreSQL Standards**: Proper upgrade paths maintained
4. **Backward Compatibility**: Existing installations can upgrade seamlessly

## Release Process

### For Releases with SQL Changes
```bash
# Bump extension version to match release
./manage_version.sh bump patch  # or minor/major
git tag v1.0.7
git push && git push --tags
```

### For Releases without SQL Changes
```bash
# Just tag the release (extension version stays same)
git tag v1.0.7-hotfix
git push && git push --tags
```

## Migration for Existing Users

Users who installed the extension before this sync can upgrade:

```sql
-- Check current version
SELECT extversion FROM pg_extension WHERE extname = 'pg_cel';

-- Upgrade to latest (1.0.6)
ALTER EXTENSION pg_cel UPDATE;

-- Verify the upgrade
SELECT extversion FROM pg_extension WHERE extname = 'pg_cel';
```

This ensures everyone is on the same version alignment going forward.
