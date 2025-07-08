#!/bin/bash

# Release script for pg-cel
# Usage: ./release.sh [version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[RELEASE]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if version is provided
if [ -z "$1" ]; then
    error "Version is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION="$1"
TAG="v$VERSION"

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid version format. Use semantic versioning (e.g., 1.0.0)"
    exit 1
fi

log "Preparing release $TAG"

# Check if we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    warn "You are not on the main branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
    error "Working directory is not clean. Please commit or stash changes."
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    error "Tag $TAG already exists"
    exit 1
fi

# Update version in relevant files
log "Updating version in files..."

# Update pg_cel.control if it has a version field
if [ -f "pg_cel.control" ]; then
    if grep -q "default_version" pg_cel.control; then
        sed -i.bak "s/default_version = .*/default_version = '$VERSION'/" pg_cel.control
        rm pg_cel.control.bak
        log "Updated version in pg_cel.control"
    fi
fi

# Update README.md if it mentions version
if [ -f "README.md" ] && grep -q "Version" README.md; then
    log "Please manually update version references in README.md if needed"
fi

# Run tests to make sure everything works
log "Running tests..."
./build.sh test

# Create and push tag
log "Creating tag $TAG..."
git add .
git commit -m "Release $TAG" || true  # Allow empty commit
git tag -a "$TAG" -m "Release $TAG

## Features
- Dynamic CEL expression evaluation with JSON data
- High-performance dual caching system
- Support for all CEL language features
- Type-safe convenience functions

## Supported Platforms
- Linux (Ubuntu) with PostgreSQL 14, 15, 16, 17
- macOS with PostgreSQL 14, 15, 16, 17

## Installation
Download the appropriate package for your platform and PostgreSQL version from the release assets."

log "Pushing tag to origin..."
git push origin "$TAG"
git push origin HEAD

log "Release $TAG has been created and pushed!"
log "GitHub Actions will now build and create the release automatically."
log "Visit https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/releases to monitor the build progress."
