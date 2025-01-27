#!/usr/bin/env bash

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PYPROJECT_FILE="pyproject.toml"
CHART_FILE="helm/Chart.yaml"
MAIN_PY_FILE="app/main.py"

# Function to display script usage
usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Updates version across all project files.
Version should be in semantic versioning format: X.Y.Z

Options:
    -h, --help     Show this help message
    --dry-run      Show what would be changed without making changes
    -v, --version  Directly specify version (skips interactive prompt)

Example:
    $(basename "$0")              # Interactive mode
    $(basename "$0") -v 1.2.3     # Direct version specification
EOF
}

# Function to check if required files exist
check_files() {
    local missing_files=0
    for file in "$PYPROJECT_FILE" "$CHART_FILE" "$MAIN_PY_FILE"; do
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}Error: Required file not found: $file${NC}" >&2
            missing_files=1
        fi
    done
    
    if [[ $missing_files -eq 1 ]]; then
        exit 1
    fi
}

# Function to validate semantic version
validate_version() {
    local version=$1
    if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Version must be in format X.Y.Z (e.g., 1.2.3)${NC}" >&2
        return 1
    fi
    return 0
}

# Function to increment version
increment_version() {
    local version=$1
    local increment_type=$2
    
    IFS='.' read -r major minor patch <<< "$version"
    
    case $increment_type in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "${major}.$((minor + 1)).0"
            ;;
        patch)
            echo "${major}.${minor}.$((patch + 1))"
            ;;
    esac
}

# Function to get current version from pyproject.toml
get_current_version() {
    local version
    version=$(grep '^version = ' "$PYPROJECT_FILE" | sed 's/version = "\(.*\)"/\1/')
    echo "$version"
}

# Function to update pyproject.toml
update_pyproject() {
    local new_version=$1
    local dry_run=$2
    
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${BLUE}Would update $PYPROJECT_FILE version to $new_version${NC}"
        return
    fi
    
    sed -i.bak "s/^version = .*/version = \"$new_version\"/" "$PYPROJECT_FILE"
    rm "${PYPROJECT_FILE}.bak"
}

# Function to update Chart.yaml
update_chart() {
    local new_version=$1
    local dry_run=$2
    
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${BLUE}Would update $CHART_FILE version to $new_version${NC}"
        return
    fi
    
    sed -i.bak "s/^version: .*/version: $new_version/" "$CHART_FILE"
    rm "${CHART_FILE}.bak"
}

# Function to update main.py
update_main() {
    local new_version=$1
    local dry_run=$2
    
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${BLUE}Would update $MAIN_PY_FILE version to $new_version${NC}"
        return
    fi
    
    sed -i.bak "s/version=\"[^\"]*\"/version=\"$new_version\"/" "$MAIN_PY_FILE"
    rm "${MAIN_PY_FILE}.bak"
}

# Function to create git commit and tag
create_git_commit() {
    local new_version=$1
    local dry_run=$2
    
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${BLUE}Would create git commit and tag v$new_version${NC}"
        return
    fi
    
    git add "$PYPROJECT_FILE" "$CHART_FILE" "$MAIN_PY_FILE"
    git commit -m "chore: bump version to $new_version"
    git tag -a "v$new_version" -m "Release version $new_version"
}

# Main execution
main() {
    # Initialize dry_run variable
    local dry_run=0
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    
    echo -e "\n${BLUE}Version Update${NC}"
    echo -e "${BLUE}──────────────${NC}"
    echo -e "Current version: ${GREEN}$current_version${NC}"
    echo
    echo "Select an option to update the version:"
    echo -e "  ${GREEN}1)${NC} Bump major version  (${current_version} → $(increment_version "$current_version" "major"))"
    echo -e "     For significant changes that break backward compatibility"
    echo
    echo -e "  ${GREEN}2)${NC} Bump minor version  (${current_version} → $(increment_version "$current_version" "minor"))"
    echo -e "     For new features that don't break existing functionality"
    echo
    echo -e "  ${GREEN}3)${NC} Bump patch version  (${current_version} → $(increment_version "$current_version" "patch"))"
    echo -e "     For bug fixes and small changes"
    echo
    echo -e "  ${GREEN}4)${NC} Set version manually"
    echo -e "     Enter a specific version number"
    echo
    echo -e "  ${YELLOW}q)${NC} Cancel"
    echo
    
    local new_version=""
    while true; do
        read -rp "Select option [1-4 or q to cancel]: " choice
        echo
        
        case $choice in
            1|2|3)
                case $choice in
                    1) new_version=$(increment_version "$current_version" "major");;
                    2) new_version=$(increment_version "$current_version" "minor");;
                    3) new_version=$(increment_version "$current_version" "patch");;
                esac
                echo -e "New version will be: ${GREEN}$new_version${NC}"
                break
                ;;
            4)
                while true; do
                    echo -e "Enter version number (${GREEN}X.Y.Z${NC} format) or 'q' to cancel:"
                    read -rp "> " new_version
                    
                    if [[ "$new_version" == "q" ]]; then
                        echo -e "${YELLOW}Operation cancelled${NC}"
                        exit 0
                    fi
                    
                    if validate_version "$new_version"; then
                        break
                    fi
                done
                break
                ;;
            q|Q)
                echo -e "${YELLOW}Operation cancelled${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Please enter 1-4 or q to cancel${NC}"
                ;;
        esac
    done
    
    echo -e "${BLUE}Current version: $current_version${NC}"
    echo -e "${BLUE}New version: $new_version${NC}"
    
    # Confirm update
    read -rp "Proceed with update? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled${NC}"
        exit 0
    fi
    
    # Update all files
    update_pyproject "$new_version" "$dry_run"
    update_chart "$new_version" "$dry_run"
    update_main "$new_version" "$dry_run"
    
    # Create git commit and tag
    create_git_commit "$new_version" "$dry_run"
    
    if [[ $dry_run -eq 1 ]]; then
        echo -e "${GREEN}Dry run completed. No changes made.${NC}"
    else
        echo -e "${GREEN}Version updated successfully to $new_version${NC}"
        echo -e "${BLUE}To complete the release, run:${NC}"
        echo -e "  git push origin master"
        echo -e "  git push origin v$new_version"
    fi
}

# Execute main function with all arguments
main "$@"