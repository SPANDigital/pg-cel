#!/bin/bash

# PostgreSQL Extension Version Management Script
# Manages extension versioning following PostgreSQL best practices
# Supports semantic versioning and creates proper upgrade paths

set -e

EXTENSION_NAME="pg_cel"
CONTROL_FILE="${EXTENSION_NAME}.control"

log() {
    echo -e "\033[0;32m[VERSION]\033[0m $1"
}

error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
    exit 1
}

# Parse semantic version
parse_version() {
    echo "$1" | sed -E 's/^v?([0-9]+\.[0-9]+\.[0-9]+).*$/\1/'
}

# Get current extension version from control file
get_current_version() {
    grep "default_version" "$CONTROL_FILE" | sed "s/.*'\([^']*\)'.*/\1/"
}

# Create upgrade script
create_upgrade_script() {
    local from_version="$1"
    local to_version="$2"
    local script_file="${EXTENSION_NAME}--${from_version}--${to_version}.sql"
    
    if [[ -f "$script_file" ]]; then
        log "Upgrade script $script_file already exists"
        return
    fi
    
    cat > "$script_file" << EOF
-- Update script from version $from_version to $to_version
-- This script contains the changes needed to upgrade $EXTENSION_NAME from $from_version to $to_version

-- Add your upgrade logic here
-- Examples:
-- CREATE OR REPLACE FUNCTION new_function(...)
-- ALTER TABLE existing_table ADD COLUMN new_column type;
-- UPDATE existing_table SET new_column = default_value;

-- Remember to follow PostgreSQL extension security guidelines:
-- SET search_path = pg_catalog, pg_temp;
EOF
    
    log "Created upgrade script: $script_file"
}

# Update control file version
update_control_version() {
    local new_version="$1"
    sed -i.bak "s/default_version = '[^']*'/default_version = '$new_version'/" "$CONTROL_FILE"
    rm "${CONTROL_FILE}.bak"
    log "Updated $CONTROL_FILE to version $new_version"
}

# Update Makefile DATA section
update_makefile() {
    local base_version="$1"
    
    # Find all SQL files and create the DATA line
    local sql_files=$(ls ${EXTENSION_NAME}--*.sql 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
    
    if [[ -n "$sql_files" ]]; then
        # Use a more robust approach to update the Makefile
        if grep -q "^DATA = " Makefile; then
            sed -i.bak "s/^DATA = .*/DATA = $sql_files/" Makefile
            rm Makefile.bak
            log "Updated Makefile DATA section: $sql_files"
        else
            error "Could not find DATA line in Makefile"
        fi
    else
        error "No SQL files found"
    fi
}

# Main version bump function
bump_version() {
    local version_type="$1"
    local current_version=$(get_current_version)
    
    if [[ -z "$current_version" ]]; then
        error "Could not determine current version from $CONTROL_FILE"
    fi
    
    log "Current extension version: $current_version"
    
    # Parse current version
    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major="${VERSION_PARTS[0]}"
    local minor="${VERSION_PARTS[1]}"
    local patch="${VERSION_PARTS[2]}"
    
    # Bump version based on type
    case "$version_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            error "Invalid version type. Use: major, minor, or patch"
            ;;
    esac
    
    local new_version="${major}.${minor}.${patch}"
    log "New extension version: $new_version"
    
    # Create upgrade script
    create_upgrade_script "$current_version" "$new_version"
    
    # Update control file
    update_control_version "$new_version"
    
    # Update Makefile
    update_makefile "$new_version"
    
    log "Version bump completed: $current_version → $new_version"
    log "Next steps:"
    log "1. Edit ${EXTENSION_NAME}--${current_version}--${new_version}.sql to add your changes"
    log "2. Test the upgrade: ALTER EXTENSION $EXTENSION_NAME UPDATE TO '$new_version';"
    log "3. Commit the changes and tag the release: git tag v$new_version"
}

# Show current status
show_status() {
    local current_version=$(get_current_version)
    log "Extension: $EXTENSION_NAME"
    log "Current version: $current_version"
    log "Available SQL files:"
    ls ${EXTENSION_NAME}--*.sql 2>/dev/null | sed 's/^/  - /' || echo "  No SQL files found"
    
    # Show available upgrade paths
    if command -v psql >/dev/null 2>&1; then
        log "Available upgrade paths (run this in psql after installing the extension):"
        echo "  SELECT * FROM pg_extension_update_paths('$EXTENSION_NAME');"
    fi
}

# Usage information
usage() {
    cat << EOF
PostgreSQL Extension Version Management

Usage: $0 <command> [options]

Commands:
  bump <major|minor|patch>  Bump version and create upgrade script
  status                    Show current version and available files
  help                      Show this help message

Examples:
  $0 bump patch            Bump patch version (1.0.0 → 1.0.1)
  $0 bump minor            Bump minor version (1.0.0 → 1.1.0)
  $0 bump major            Bump major version (1.0.0 → 2.0.0)
  $0 status                Show current status

Note: This script follows PostgreSQL extension best practices:
- Uses semantic versioning (major.minor.patch)
- Creates upgrade scripts for version transitions
- Updates control file and Makefile automatically
EOF
}

# Main script logic
case "${1:-help}" in
    bump)
        if [[ -z "$2" ]]; then
            error "Version type required. Use: major, minor, or patch"
        fi
        bump_version "$2"
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1. Use '$0 help' for usage information."
        ;;
esac
