# GitHub Actions CI/CD Setup Summary

This document summarizes the CI/CD pipeline setup for the pg-cel PostgreSQL extension.

## Files Created

### GitHub Actions Workflows
- `.github/workflows/ci.yml` - Continuous Integration for every push/PR
- `.github/workflows/build-and-release.yml` - Build and release for tagged versions

### Scripts
- `release.sh` - Script to create and push new releases
- `test-gha.sh` - Script to test GitHub Actions locally with 'act'

### Documentation
- `INSTALL.md` - Comprehensive installation guide for end users
- Updated `README.md` with CI/CD information

### Configuration
- Updated `.gitignore` with PostgreSQL extension specific entries
- Updated `pg_cel.control` with semantic versioning

## Workflow Overview

### Continuous Integration (CI)
**Triggers:** Push to main/develop, Pull Requests to main
**Platforms:** Ubuntu Latest, macOS Latest
**PostgreSQL:** Version 16
**Actions:**
1. Checkout code
2. Setup Go 1.21
3. Install PostgreSQL with dev headers
4. Download dependencies
5. Build extension
6. Run tests

### Build and Release
**Triggers:** Git tags starting with 'v' (e.g., v1.0.0)
**Platforms:** Ubuntu Latest, macOS Latest  
**PostgreSQL Versions:** 14, 15, 16, 17
**Actions:**
1. Build extension for each platform/PG version combination
2. Run comprehensive tests
3. Package artifacts as tar.gz files
4. Create GitHub release with all packages
5. Generate release notes automatically

## Release Process

### Creating a Release

1. **Prepare the release:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create and push the release:**
   ```bash
   ./release.sh 1.0.0
   ```

3. **Monitor the build:**
   - Visit GitHub Actions tab to monitor build progress
   - Check the Releases page for the completed release

### Manual Release (Alternative)

1. **Tag the release:**
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build for all supported platforms/versions
   - Run tests
   - Create release with artifacts

## Artifacts Generated

For each release, the following packages are generated:

### Linux Packages
- `pg-cel-linux-pg14.tar.gz`
- `pg-cel-linux-pg15.tar.gz` 
- `pg-cel-linux-pg16.tar.gz`
- `pg-cel-linux-pg17.tar.gz`

### macOS Packages
- `pg-cel-macos-pg14.tar.gz`
- `pg-cel-macos-pg15.tar.gz`
- `pg-cel-macos-pg16.tar.gz`
- `pg-cel-macos-pg17.tar.gz`

Each package contains:
- Compiled shared library (`.so` for Linux, `.dylib` for macOS)
- Control file (`pg_cel.control`)
- SQL definition file (`pg_cel--1.0.sql`)
- Documentation (`README.md`, `LICENSE`)

## Testing

### Local Testing
```bash
./build.sh test
```

### GitHub Actions Testing (Local)
```bash
# Requires 'act' to be installed
./test-gha.sh ci       # Test CI workflow
./test-gha.sh release  # Test release workflow (dry run)
```

### Platform Testing
The CI automatically tests on:
- Ubuntu Latest with PostgreSQL 16
- macOS Latest with PostgreSQL 16

The release workflow tests on:
- Ubuntu Latest with PostgreSQL 14, 15, 16, 17
- macOS Latest with PostgreSQL 14, 15, 16, 17

## Badge Status

Add these badges to your README.md:

```markdown
![CI](https://github.com/your-username/pg-cel/workflows/CI/badge.svg)
![Build and Release](https://github.com/your-username/pg-cel/workflows/Build%20and%20Release/badge.svg)
```

## Security Considerations

- The workflows use pinned action versions (@v4)
- Only GitHub's `GITHUB_TOKEN` is used (no custom secrets needed)
- Release artifacts are signed by GitHub Actions
- Dependencies are verified with `go mod verify`

## Future Improvements

- Add Windows support when PostgreSQL for Windows is needed
- Add code coverage reporting
- Add performance benchmarking in CI
- Consider multi-architecture builds (ARM64, AMD64)
- Add automatic vulnerability scanning
