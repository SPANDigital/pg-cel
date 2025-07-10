# CI/CD Debug Report: PostgreSQL 17 Package Installation Failure

## Issue Summary
**Date**: July 10, 2025  
**Workflow Run**: https://github.com/SPANDigital/pg-cel/actions/runs/16199538759/job/45734767682  
**Status**: ❌ FAILED  
**Root Cause**: PostgreSQL 17 development packages not available in Ubuntu's default repositories  

## Problem Analysis

### Failed Job Details
- **Matrix Combination**: PostgreSQL 17 + Go 1.23
- **Runner**: ubuntu-latest (Ubuntu 22.04 LTS)
- **Failure Point**: "Install PostgreSQL client and dev packages" step
- **Other Versions**: Cancelled after PostgreSQL 17 failure

### Root Cause
The workflow attempted to install `postgresql-server-dev-17` using Ubuntu's default APT repositories:
```bash
sudo apt-get install -y postgresql-client postgresql-server-dev-17
```

However, Ubuntu 22.04's default repositories only include PostgreSQL packages up to version 14/15. PostgreSQL 17 packages are only available from the official PostgreSQL APT repository.

### Error Pattern
```
Package 'postgresql-server-dev-17' has no installation candidate
```

## Solution Implemented

### 1. Added PostgreSQL Official Repository
Modified the workflow to add the PostgreSQL official APT repository before package installation:

```yaml
- name: Install PostgreSQL client and dev packages
  run: |
    # Add PostgreSQL official APT repository
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    sudo apt-get update
    sudo apt-get install -y postgresql-client postgresql-server-dev-${{ matrix.postgres-version }}
```

### 2. Enhanced Debugging
Added comprehensive debugging output for future troubleshooting:

#### pg_config Verification
```yaml
- name: Set PG_CONFIG environment
  run: |
    echo "PG_CONFIG=/usr/lib/postgresql/${{ matrix.postgres-version }}/bin/pg_config" >> $GITHUB_ENV
    # Verify pg_config is available
    ls -la /usr/lib/postgresql/${{ matrix.postgres-version }}/bin/pg_config
    /usr/lib/postgresql/${{ matrix.postgres-version }}/bin/pg_config --version
```

#### Build Process Debugging
```yaml
- name: Build pg-cel extension
  run: |
    export PG_CONFIG=/usr/lib/postgresql/${{ matrix.postgres-version }}/bin/pg_config
    echo "Building with PostgreSQL version: ${{ matrix.postgres-version }}"
    echo "PG_CONFIG path: $PG_CONFIG"
    echo "Go version: $(go version)"
    ./build.sh
```

#### Database Setup Logging
```yaml
- name: Setup test database
  run: |
    echo "Waiting for PostgreSQL ${{ matrix.postgres-version }} to be ready..."
    # ... detailed logging for each step
    echo "PostgreSQL is ready. Creating test database..."
    echo "Installing pg-cel extension..."
    echo "Verifying pg-cel extension works..."
```

## Technical Details

### Package Verification
Confirmed PostgreSQL 17 packages are available in the official repository:
```bash
$ curl -s "https://apt.postgresql.org/pub/repos/apt/dists/jammy-pgdg/main/binary-amd64/Packages.gz" | gunzip | grep "Package: postgresql-server-dev-17"
Package: postgresql-server-dev-17
Source: postgresql-17
Version: 17.5-1.pgdg22.04+1
```

### Security Considerations
- Used official PostgreSQL GPG key: `ACCC4CF8.asc`
- Added repository to trusted sources: `/etc/apt/trusted.gpg.d/postgresql.gpg`
- Repository URL: `http://apt.postgresql.org/pub/repos/apt/`

## Expected Outcome

With these fixes, the workflow should now:
1. ✅ Successfully install PostgreSQL 17 development packages
2. ✅ Build pg-cel extension for all PostgreSQL versions (14, 15, 16, 17)
3. ✅ Run BDD tests across all matrix combinations
4. ✅ Provide detailed debugging output for any future issues

## Monitoring

The next workflow run will validate:
- PostgreSQL APT repository addition
- Package installation success for PostgreSQL 17
- Extension build and installation
- BDD test execution across all PostgreSQL versions

## Related Files Modified
- `.github/workflows/bdd-tests.yml` - Main workflow fixes and debugging
- `CI_CD_WORKFLOW_IMPROVEMENTS.md` - Documentation updates

## Commit Reference
- **Commit**: `d030d75` - "Fix PostgreSQL 17 CI failure and improve debugging"
- **Branch**: `feature/godog-testing`
- **Status**: Pushed and ready for CI validation

This fix addresses the core issue while providing robust debugging capabilities for future CI/CD maintenance.
