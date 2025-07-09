#!/bin/bash

# Simple script to update extension version for testing
# Usage: ./update_version.sh <version>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.7"
    exit 1
fi

VERSION="$1"

echo "Updating extension version to $VERSION..."

# Update pg_cel.control
if [ -f "pg_cel.control" ]; then
    sed -i.bak "s/default_version = .*/default_version = '$VERSION'/" pg_cel.control
    rm pg_cel.control.bak
    echo "✓ Updated pg_cel.control"
fi

# Handle SQL file versioning
OLD_SQL_FILE=$(ls pg_cel--*.sql 2>/dev/null | head -1)
NEW_SQL_FILE="pg_cel--$VERSION.sql"

if [ -n "$OLD_SQL_FILE" ] && [ "$OLD_SQL_FILE" != "$NEW_SQL_FILE" ]; then
    if [ -f "$OLD_SQL_FILE" ]; then
        cp "$OLD_SQL_FILE" "$NEW_SQL_FILE"
        echo "✓ Created $NEW_SQL_FILE"
    fi
fi

echo "Extension version updated to $VERSION"
echo "Files updated:"
echo "  - pg_cel.control (default_version = '$VERSION')"
echo "  - $NEW_SQL_FILE"
