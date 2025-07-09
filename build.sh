#!/bin/bash

# Cross-platform build script for pg-cel PostgreSQL extension
# Usage: ./build.sh [clean|deps|build|install|test|package]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM=Linux;;
        Darwin*)    PLATFORM=macOS;;
        CYGWIN*|MINGW*|MSYS*)    PLATFORM=Windows;;
        *)          PLATFORM="Unknown";;
    esac
    log "Detected platform: $PLATFORM"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."

    # Check Go
    if ! command -v go &> /dev/null; then
        error "Go is not installed or not in PATH"
        exit 1
    fi
    log "Go version: $(go version)"

    # Check PostgreSQL
    if ! command -v pg_config &> /dev/null; then
        error "PostgreSQL development packages not found (pg_config missing)"
        error "Install postgresql-server-dev (Ubuntu) or postgresql (macOS/Windows)"
        exit 1
    fi
    log "PostgreSQL version: $(pg_config --version)"

    # Check make
    if ! command -v make &> /dev/null; then
        error "Make is not installed"
        exit 1
    fi
}

# Download Go dependencies
download_deps() {
    log "Downloading Go dependencies..."
    go mod download
    go mod verify
}

# Build the extension
build_extension() {
    log "Building Go archive..."
    go build -buildmode=c-archive -o pg_cel_go.a main.go
    if [ $? -ne 0 ]; then
        error "Failed to build Go archive"
        return 1
    fi

    log "Building PostgreSQL extension..."
    case $PLATFORM in
        Linux)
            make clean
            make SHLIB_LINK="pg_cel_go.a"
            ;;
        macOS)
            make clean
            # On macOS, we need additional flags for dynamic linking
            make SHLIB_LINK="-undefined dynamic_lookup pg_cel_go.a -lresolv -framework CoreFoundation"
            ;;
        Windows)
            make clean
            make SHLIB_LINK="pg_cel_go.a"
            ;;
        *)
            error "Unsupported platform: $PLATFORM"
            return 1
            ;;
    esac

    # Check if build was successful - macOS can produce either .dylib or .so
    if [[ "$PLATFORM" == "Linux" && ! -f pg_cel.so ]]; then
        error "Build failed: pg_cel.so not found"
        return 1
    elif [[ "$PLATFORM" == "macOS" && ! -f pg_cel.dylib && ! -f pg_cel.so ]]; then
        error "Build failed: neither pg_cel.dylib nor pg_cel.so was found"
        return 1
    elif [[ "$PLATFORM" == "Windows" && ! -f pg_cel.dll ]]; then
        error "Build failed: pg_cel.dll not found"
        return 1
    fi

    log "Build completed successfully!"
    return 0
}

# Install the extension
install_extension() {
    log "Installing extension..."
    if [[ "$PLATFORM" == "Linux" ]]; then
        sudo make install
    else
        make install
    fi
    log "Extension installed successfully!"
}

# Run tests
run_tests() {
    log "Running tests..."

    # Create test database
    DB_NAME="pg_cel_test"

    case $PLATFORM in
        Linux)
            sudo -u postgres createdb $DB_NAME || true
            sudo -u postgres psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS pg_cel;"
            sudo -u postgres psql -d $DB_NAME -f test.sql
            sudo -u postgres dropdb $DB_NAME
            ;;
        macOS)
            createdb $DB_NAME || true
            psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS pg_cel;"
            psql -d $DB_NAME -f test.sql
            dropdb $DB_NAME
            ;;
        Windows)
            createdb $DB_NAME || true
            psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS pg_cel;"
            psql -d $DB_NAME -f test.sql
            dropdb $DB_NAME
            ;;
    esac

    log "Tests completed successfully!"
}

# Clean build artifacts
clean_build() {
    log "Cleaning build artifacts..."
    make clean
    rm -f *.o *.so *.dylib *.dll
    log "Clean completed!"
}

# Package for distribution
package_extension() {
    log "Packaging extension..."

    PG_VERSION=$(pg_config --version | sed 's/PostgreSQL \([0-9]*\).*/\1/')
    PACKAGE_NAME="pg-cel-${PLATFORM,,}-pg${PG_VERSION}"
    
    mkdir -p dist/$PACKAGE_NAME

    # Copy built files
    cp pg_cel.* dist/$PACKAGE_NAME/ 2>/dev/null || true
    cp pg_cel_go.h dist/$PACKAGE_NAME/ 2>/dev/null || true
    
    # Always copy the standard SQL file
    cp pg_cel--1.0.sql dist/$PACKAGE_NAME/ 2>/dev/null || true

    # Create archive
    cd dist
    tar -czf $PACKAGE_NAME.tar.gz $PACKAGE_NAME
    cd ..

    log "Package created: dist/$PACKAGE_NAME.tar.gz (PostgreSQL $PG_VERSION)"
}

# Get extension version from pg_cel.control
get_extension_version() {
    if [ -f "pg_cel.control" ]; then
        VERSION=$(grep "default_version" pg_cel.control | sed "s/default_version = '\(.*\)'/\1/" | tr -d "'" | tr -d ' ')
        if [ -z "$VERSION" ]; then
            VERSION="1.0"
        fi
    else
        VERSION="1.0"
    fi
    echo "$VERSION"
}

# Main script logic
main() {
    detect_platform

    case "${1:-build}" in
        clean)
            clean_build
            ;;
        deps)
            check_dependencies
            download_deps
            ;;
        build)
            check_dependencies
            download_deps
            build_extension
            ;;
        install)
            check_dependencies
            download_deps
            build_extension
            install_extension
            ;;
        test)
            check_dependencies
            download_deps
            build_extension
            install_extension
            run_tests
            ;;
        package)
            check_dependencies
            download_deps
            build_extension
            package_extension
            ;;
        *)
            echo "Usage: $0 [clean|deps|build|install|test|package]"
            echo ""
            echo "Commands:"
            echo "  clean   - Clean build artifacts"
            echo "  deps    - Check dependencies and download Go modules"
            echo "  build   - Build the extension (default)"
            echo "  install - Build and install the extension"
            echo "  test    - Build, install, and run tests"
            echo "  package - Build and create distribution package"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
