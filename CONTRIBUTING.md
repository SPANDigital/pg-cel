# Contributing to pg-cel

Thank you for your interest in contributing to pg-cel! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Contributing Guidelines](#contributing-guidelines)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a code of conduct that ensures a welcoming and inclusive environment for all contributors. Please be respectful and professional in all interactions.

## Getting Started

pg-cel is a PostgreSQL extension that integrates Google's CEL (Common Expression Language) with PostgreSQL, allowing you to evaluate CEL expressions directly within SQL queries with high-performance caching.

### Prerequisites

- **Go 1.24+**: The project uses Go 1.24 for modern language features and performance improvements
- **PostgreSQL 14, 15, 16, or 17**: Development headers and libraries required
- **Git**: For version control
- **Make**: For build automation

### Quick Start

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/pg-cel.git
   cd pg-cel
   ```

2. **Install Dependencies**
   ```bash
   go mod download
   ```

3. **Build the Extension**
   ```bash
   ./build.sh
   ```

4. **Run Tests**
   ```bash
   ./build.sh test
   ```

## Development Environment

### macOS Setup

```bash
# Install PostgreSQL (choose your version)
brew install postgresql@16

# Set environment variables
export PG_CONFIG=/opt/homebrew/opt/postgresql@16/bin/pg_config
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

### Linux Setup

```bash
# Install PostgreSQL and development headers
sudo apt-get install postgresql-16 postgresql-server-dev-16 build-essential

# Set environment variables
export PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config
export PATH="/usr/lib/postgresql/16/bin:$PATH"
```

### Go Version

This project uses Go 1.24 for modern language features including:
- Native `any` type (instead of `interface{}`)
- Enhanced performance optimizations
- Improved CGO integration

## Project Structure

```
pg-cel/
├── main.go              # Go backend with CEL evaluation logic
├── pg_wrapper.c         # C wrapper for PostgreSQL integration
├── pg_cel--*.sql        # SQL function definitions (versioned)
├── pg_cel.control       # Extension control file
├── Makefile            # Build system
├── build.sh            # Cross-platform build script
├── test.sql            # Test suite
├── .github/workflows/   # CI/CD pipelines
└── docs/               # Documentation
```

### Key Components

1. **Go Backend (`main.go`)**
   - Implements CEL evaluation using CGO exports
   - Manages dual caching system (program cache + JSON cache)
   - Handles error reporting and type conversions

2. **C Wrapper (`pg_wrapper.c`)**
   - Provides PostgreSQL C extension interface
   - Bridges Go functions with PostgreSQL's C API
   - Manages configuration parameters

3. **SQL Interface (`pg_cel--*.sql`)**
   - Defines PostgreSQL functions
   - Handles extension installation and upgrades
   - Manages version transitions

## Contributing Guidelines

### Code Style

**Go Code:**
- Follow standard Go conventions (`gofmt`, `go vet`)
- Use `any` instead of `interface{}` for Go 1.24+ compatibility
- Prefix exported CGO functions with `pg_cel_*`
- Use camelCase for helper functions
- Include comprehensive error handling

**C Code:**
- Follow PostgreSQL coding standards
- Use consistent indentation (tabs)
- Include proper error handling and memory management

**SQL Code:**
- Use lowercase for SQL keywords
- Include proper documentation comments
- Follow PostgreSQL naming conventions

### Performance Considerations

- **Caching Strategy**: Use dual caching (program cache + JSON cache)
- **Hash Functions**: Use FNV for cache keys (non-cryptographic, optimized for speed)
- **Memory Management**: Follow PostgreSQL memory context patterns
- **Error Handling**: Provide meaningful error messages with context

### Adding New Features

1. **CGO Functions**: Follow the export pattern
   ```go
   //export pg_cel_new_function
   func pg_cel_new_function(param *C.char) *C.char {
       // Implementation
   }
   ```

2. **C Wrapper**: Add corresponding C wrapper in `pg_wrapper.c`

3. **SQL Functions**: Define in the appropriate `pg_cel--*.sql` file

4. **Tests**: Add comprehensive test cases in `test.sql`

5. **Documentation**: Update `EXAMPLES.md` with usage examples

### Version Management

Use the provided version management script for consistent versioning:

```bash
# Bump patch version (1.3.2 → 1.3.3)
./manage_version.sh bump patch

# Bump minor version (1.3.2 → 1.4.0)
./manage_version.sh bump minor

# Bump major version (1.3.2 → 2.0.0)
./manage_version.sh bump major
```

This automatically:
- Updates version in `pg_cel.control`
- Creates new SQL files
- Generates upgrade scripts
- Updates `Makefile` with new file listings

## Testing

### Local Testing

```bash
# Build and run all tests
./build.sh test

# Test specific PostgreSQL version
PG_CONFIG=/path/to/pg_config ./build.sh test

# Run only compilation tests
./build.sh
```

### CI/CD Testing

The project includes comprehensive CI/CD testing:

- **Matrix Testing**: PostgreSQL 14, 15, 16, 17 on Linux and macOS
- **Multi-platform**: Ubuntu and macOS runners
- **Automated Releases**: Tag-based releases with artifacts

All tests must pass before merging:
```bash
# Check CI status
gh run list

# View specific run
gh run view <run-id>
```

### Test Coverage

When adding new features, ensure:

1. **Unit Tests**: Test individual functions
2. **Integration Tests**: Test complete workflows  
3. **Edge Cases**: Test error conditions and boundary cases
4. **Performance Tests**: Verify cache behavior and performance
5. **Cross-Version Tests**: Ensure compatibility across PostgreSQL versions

## Submitting Changes

### Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow coding standards
   - Include comprehensive tests
   - Update documentation

3. **Test Locally**
   ```bash
   ./build.sh test
   ```

4. **Commit Changes**
   ```bash
   git commit -m "feat: add new feature description"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format

Follow conventional commits:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions/modifications
- `refactor:` Code refactoring
- `perf:` Performance improvements

### PR Requirements

- [ ] All tests pass
- [ ] Code follows project conventions
- [ ] Documentation updated
- [ ] Examples provided for new features
- [ ] Version bumped if needed

## Release Process

### For Maintainers

1. **Version Management**
   ```bash
   ./manage_version.sh bump [patch|minor|major]
   ```

2. **Testing**
   ```bash
   ./build.sh test
   ```

3. **Commit and Tag**
   ```bash
   git add -A
   git commit -m "feat: bump version to X.Y.Z"
   git tag vX.Y.Z
   git push origin main
   git push origin vX.Y.Z
   ```

4. **Release Notes**
   - Automated via GitHub Actions
   - Include changelog and artifacts
   - Document breaking changes

### Release Artifacts

Each release includes:
- Linux binaries for PostgreSQL 14, 15, 16, 17
- macOS binaries for PostgreSQL 14, 15, 16, 17
- Source code archives
- Installation instructions

## Getting Help

### Documentation

- **README.md**: Overview and quick start
- **INSTALL.md**: Detailed installation instructions
- **EXAMPLES.md**: Usage examples and patterns
- **TROUBLESHOOTING.md**: Common issues and solutions

### Community

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Pull Requests**: Code contributions and reviews

### Development Questions

For development-specific questions:

1. Check existing issues and documentation
2. Search closed issues for similar problems
3. Create a new issue with:
   - Clear problem description
   - Environment details (OS, PostgreSQL version, Go version)
   - Reproduction steps
   - Expected vs actual behavior

## License

By contributing to pg-cel, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to pg-cel! Your efforts help make this project better for everyone.
