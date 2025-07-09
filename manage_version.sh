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
    local new_version="$1"
    
    # Find all SQL files and organize them
    local install_scripts=$(ls ${EXTENSION_NAME}--[0-9]*.sql 2>/dev/null | grep -v -- '--.*--' | sort -V | tr '\n' ' ' | sed 's/ $//')
    local upgrade_scripts=$(ls ${EXTENSION_NAME}--*--*.sql 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')
    
    if [[ -n "$install_scripts" || -n "$upgrade_scripts" ]]; then
        # Use a more robust approach to update the Makefile
        if grep -q "^INSTALL_SCRIPTS = " Makefile; then
            # Update existing organized structure
            sed -i.bak "s/^INSTALL_SCRIPTS = .*/INSTALL_SCRIPTS = $install_scripts/" Makefile
            sed -i.bak "s/^UPGRADE_SCRIPTS = .*/UPGRADE_SCRIPTS = $upgrade_scripts/" Makefile
            rm Makefile.bak 2>/dev/null || true
            log "Updated Makefile with organized structure"
        elif grep -q "^DATA = " Makefile; then
            # Convert old structure to new organized structure
            local all_scripts="$install_scripts $upgrade_scripts"
            sed -i.bak "s/^DATA = .*/DATA = $all_scripts/" Makefile
            rm Makefile.bak
            log "Updated Makefile DATA section: $all_scripts"
        else
            error "Could not find DATA line in Makefile"
        fi
        
        log "  Install scripts: $install_scripts"
        log "  Upgrade scripts: $upgrade_scripts"
    else
        error "No SQL files found"
    fi
}

# Clean up old versions (keep only latest N versions)
cleanup_old_versions() {
    local keep_versions=${1:-3}  # Default: keep latest 3 versions
    
    log "Cleaning up old extension versions (keeping latest $keep_versions versions)..."
    
    # Get all install scripts sorted by version
    local install_scripts=($(ls ${EXTENSION_NAME}--[0-9]*.sql 2>/dev/null | grep -v -- '--.*--' | sort -V))
    local total_installs=${#install_scripts[@]}
    
    if [[ $total_installs -le $keep_versions ]]; then
        log "Only $total_installs installation scripts found, nothing to clean up"
        return
    fi
    
    # Calculate how many to remove
    local to_remove=$((total_installs - keep_versions))
    log "Found $total_installs installation scripts, removing oldest $to_remove"
    
    # Remove oldest install scripts and their associated upgrade scripts
    for ((i=0; i<to_remove; i++)); do
        local old_script="${install_scripts[i]}"
        local version=$(echo "$old_script" | sed "s/${EXTENSION_NAME}--\([^.]*\.[^.]*\.[^.]*\)\.sql/\1/")
        
        log "Removing version $version files:"
        
        # Remove install script
        if [[ -f "$old_script" ]]; then
            log "  - $old_script"
            rm "$old_script"
        fi
        
        # Remove upgrade scripts involving this version
        local upgrade_scripts=$(ls ${EXTENSION_NAME}--*${version}*.sql 2>/dev/null | grep -- '--.*--' || true)
        if [[ -n "$upgrade_scripts" ]]; then
            echo "$upgrade_scripts" | while read -r upgrade_script; do
                if [[ -f "$upgrade_script" ]]; then
                    log "  - $upgrade_script"
                    rm "$upgrade_script"
                fi
            done
        fi
    done
    
    # Update Makefile
    update_makefile $(get_current_version)
    
    log "Cleanup completed. Run './manage_version.sh status' to see current files."
}
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
    
    # Show organized file listing
    local install_scripts=$(ls ${EXTENSION_NAME}--[0-9]*.sql 2>/dev/null | grep -v -- '--.*--' | sort -V)
    local upgrade_scripts=$(ls ${EXTENSION_NAME}--*--*.sql 2>/dev/null | sort)
    
    if [[ -n "$install_scripts" ]]; then
        log "Installation scripts:"
        echo "$install_scripts" | sed 's/^/  - /'
    fi
    
    if [[ -n "$upgrade_scripts" ]]; then
        log "Upgrade scripts:"
        echo "$upgrade_scripts" | sed 's/^/  - /'
    fi
    
    if [[ -z "$install_scripts" && -z "$upgrade_scripts" ]]; then
        log "No SQL files found"
    fi
    
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
  cleanup [N]               Remove old versions (keep latest N, default: 3)
  help                      Show this help message

Examples:
  $0 bump patch            Bump patch version (1.0.0 → 1.0.1)
  $0 bump minor            Bump minor version (1.0.0 → 1.1.0)
  $0 bump major            Bump major version (1.0.0 → 2.0.0)
  $0 status                Show current status with organized file listing
  $0 cleanup 2             Keep only latest 2 versions, remove older ones
  $0 cleanup               Keep only latest 3 versions (default)

Note: This script follows PostgreSQL extension best practices:
- Uses semantic versioning (major.minor.patch)
- Creates upgrade scripts for version transitions
- Updates control file and Makefile automatically
- Organizes files by type (installation vs upgrade scripts)
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
    cleanup)
        cleanup_old_versions "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1. Use '$0 help' for usage information."
        ;;
esac
