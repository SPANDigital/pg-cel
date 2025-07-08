#!/bin/bash

# Script to test GitHub Actions locally using 'act'
# Install act: https://github.com/nektos/act

set -e

log() {
    echo -e "\033[0;32m[TEST-GHA]\033[0m $1"
}

error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Check if act is installed
if ! command -v act &> /dev/null; then
    error "act is not installed. Install it from: https://github.com/nektos/act"
    error "Or run the workflows manually by pushing to GitHub"
    exit 1
fi

log "Testing GitHub Actions locally with act..."

case "${1:-ci}" in
    ci)
        log "Running CI workflow..."
        act -W .github/workflows/ci.yml
        ;;
    release)
        log "Running release workflow (dry run)..."
        act -W .github/workflows/build-and-release.yml --dry-run
        ;;
    *)
        echo "Usage: $0 [ci|release]"
        echo ""
        echo "Commands:"
        echo "  ci      - Test CI workflow"
        echo "  release - Test release workflow (dry run)"
        exit 1
        ;;
esac

log "GitHub Actions test completed!"
