#!/bin/bash

# Version Updater Script
# Reads the version from helm/Chart.yaml in the parent directory, updates it and
# pyproject.toml (if found), and provides options to bump the version.
# Designed to be run from within the 'scripts' directory of a generated service.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration ---
# Determine the directory where the script resides
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Project root is one level up
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CHART_FILE="${PROJECT_ROOT}/helm/Chart.yaml"
PYPROJECT_FILE="${PROJECT_ROOT}/pyproject.toml"
COMMIT_CHANGES=1 # 0=no, 1=yes

# --- Helper Functions ---

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print error messages and exit
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to determine which version of yq is installed (if any)
detect_yq_version() {
    if ! command_exists yq; then
        echo "none"
        return
    fi
    
    # Try to detect if it's Go yq (mikefarah) or Python yq
    yq_version=$(yq --version 2>&1 || true)
    if [[ "$yq_version" =~ "mikefarah" ]] || [[ "$yq_version" =~ "https://github.com/mikefarah/yq" ]]; then
        echo "go"
    elif [[ "$yq_version" =~ "jq" ]] || [[ "$yq_version" =~ "kislyuk" ]]; then
        echo "python"
    else
        # Try a heuristic approach - Go version has 'eval' command
        if yq eval --help &>/dev/null; then
            echo "go"
        else
            echo "unknown"
        fi
    fi
}

# Function to extract version from Chart.yaml with fallbacks
extract_chart_version() {
    local chart_file="$1"
    local version=""
    local yq_type=$(detect_yq_version)
    
    # Try using yq first (handle different variants)
    if [[ "$yq_type" == "go" ]]; then
        # Go version syntax (mikefarah/yq)
        version=$(yq eval '.version' "$chart_file" 2>/dev/null || yq e '.version' "$chart_file" 2>/dev/null || echo "")
    elif [[ "$yq_type" == "python" ]]; then
        # Python version syntax
        version=$(yq -y '.version' "$chart_file" 2>/dev/null || echo "")
    fi
    
    # If yq failed or returned empty, try grep as fallback
    if [ -z "$version" ] || [ "$version" == "null" ]; then
        version=$(grep -E '^version:' "$chart_file" 2>/dev/null | sed 's/version:[[:space:]]*\(.*\)/\1/' | tr -d '"' | tr -d "'" || echo "")
    fi
    
    # If still empty, try awk
    if [ -z "$version" ]; then
        version=$(awk '/^version:/ {print $2}' "$chart_file" 2>/dev/null | tr -d '"' | tr -d "'" || echo "")
    fi
    
    echo "$version"
}

# Function to update version in Chart.yaml with fallbacks
update_chart_version() {
    local chart_file="$1"
    local new_version="$2"
    local success=false
    local yq_type=$(detect_yq_version)
    
    # Create a backup first
    cp "$chart_file" "${chart_file}.bak"
    
    # Try using yq first (handle different variants)
    if [[ "$yq_type" == "go" ]]; then
        # Go version syntax (mikefarah/yq)
        yq eval ".version = \"$new_version\"" -i "$chart_file" 2>/dev/null && \
        yq eval ".appVersion = \"$new_version\"" -i "$chart_file" 2>/dev/null && success=true
        
        # Try alternate syntax if the first one failed
        if [ "$success" != "true" ]; then
            yq e ".version = \"$new_version\"" -i "$chart_file" 2>/dev/null && \
            yq e ".appVersion = \"$new_version\"" -i "$chart_file" 2>/dev/null && success=true
        fi
    elif [[ "$yq_type" == "python" ]]; then
        # Python version can't do in-place edits easily, so we use a temp file
        local temp_file="${chart_file}.tmp"
        yq -y --arg ver "$new_version" '.version = $ver | .appVersion = $ver' "$chart_file" > "$temp_file" 2>/dev/null && \
        mv "$temp_file" "$chart_file" && success=true
    fi
    
    # If yq failed, try sed as fallback
    if [ "$success" != "true" ]; then
        sed -i.tmp -e "s/^version:.*$/version: $new_version/" "$chart_file" && \
        sed -i.tmp -e "s/^appVersion:.*$/appVersion: $new_version/" "$chart_file" && \
        rm -f "${chart_file}.tmp" && success=true
    fi
    
    # Check if update was successful
    if [ "$success" != "true" ]; then
        # Restore from backup
        mv "${chart_file}.bak" "$chart_file"
        return 1
    fi
    
    # Remove backup on success
    rm -f "${chart_file}.bak"
    return 0
}

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

# Function to validate semantic version
validate_version() {
    local version=$1
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-].*)?$ ]]; then
        die "Invalid version format: $version. Expected format: X.Y.Z"
    fi
    echo "$version"
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

# Function to get current version from Chart.yaml
get_current_version() {
    if [ ! -f "$CHART_FILE" ]; then
        die "Helm chart file not found at: $CHART_FILE. Ensure the script is in a 'scripts' subdirectory and 'helm/Chart.yaml' exists one level up."
    fi
    
    local version
    version=$(extract_chart_version "$CHART_FILE")
    
    if [ -z "$version" ]; then
        die "Could not extract version from $CHART_FILE. Please check the file format."
    fi
    
    echo "$version"
}

# Function to update version in Chart.yaml and pyproject.toml
update_versions() {
    local new_version="$1"
    local current_version="$2"
    local files_to_commit=()

    echo -e "Updating ${BLUE}$CHART_FILE${NC}..."
    if update_chart_version "$CHART_FILE" "$new_version"; then
        echo -e "${GREEN}Updated $CHART_FILE to version $new_version${NC}"
        files_to_commit+=("$CHART_FILE")
    else
        die "Failed to update version in $CHART_FILE."
    fi

    # Update pyproject.toml if it exists
    if [ -f "$PYPROJECT_FILE" ]; then
        echo -e "Updating ${BLUE}$PYPROJECT_FILE${NC}..."
        # Change directory temporarily for sed to work relative to project root with backup
        (cd "$PROJECT_ROOT" && sed -i.bak "s/^version = .*/version = \"$new_version\"/" "$(basename "$PYPROJECT_FILE")")
        if [ $? -ne 0 ]; then
            # Attempt to restore from backup if sed failed
            if [ -f "${PYPROJECT_FILE}.bak" ]; then
                 mv "${PYPROJECT_FILE}.bak" "$PYPROJECT_FILE"
            fi
            die "Failed to update version in $PYPROJECT_FILE."
        fi
        rm -f "${PYPROJECT_FILE}.bak" # Remove backup on success
        echo -e "${GREEN}Updated $PYPROJECT_FILE to version $new_version${NC}"
        files_to_commit+=("$PYPROJECT_FILE")
    else
        echo -e "${YELLOW}Skipping $PYPROJECT_FILE: File not found.${NC}"
    fi

    # Return list of updated files for commit
    echo "${files_to_commit[@]}"
}

# Function to create git commit and tag
create_git_commit() {
    local new_version="$1"
    local dry_run="$2"
    shift 2 # Remove version and dry_run from arguments
    local files_to_add=($@) # Remaining arguments are files to add
    local files_to_add_git=()

    if [ $dry_run -ne 0 ]; then
        echo -e "${BLUE}Dry run: Would commit changes to: ${files_to_add[*]}${NC}"
        return
    fi

    if [ ${#files_to_add[@]} -eq 0 ]; then
        echo -e "${YELLOW}No files were updated, skipping commit.${NC}"
        return
    fi
    
    # Use the file paths directly - they're already absolute
    # Strip color codes to avoid realpath issues
    echo -e "${BLUE}Git: Processing files for commit${NC}"
    # Hard-code the known files to avoid path issues
    (cd "$PROJECT_ROOT" && git add "helm/Chart.yaml")
    if [ -f "$PYPROJECT_FILE" ]; then
        (cd "$PROJECT_ROOT" && git add "pyproject.toml")
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to stage files with git add in $PROJECT_ROOT.${NC}"
        echo -e "${YELLOW}Please check your Git status and stage/commit manually.${NC}"
        return # Don't attempt commit if add failed
    fi

    echo -e "${BLUE}Committing from $PROJECT_ROOT with message: chore: Bump version to $new_version${NC}"
    # Run git commit from the project root directory
    (cd "$PROJECT_ROOT" && git commit -m "chore: Bump version to $new_version")
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Failed to commit changes. Maybe no changes to commit, or another Git issue? Please check manually.${NC}"
    else
        echo -e "${GREEN}Changes committed in $PROJECT_ROOT.${NC}"
        echo -e "${BLUE}Consider running from $PROJECT_ROOT: git tag v$new_version && git push origin HEAD && git push origin v$new_version${NC}"
    fi
}

# Main execution
main() {
    # Check for any tool dependencies
    local missing_tools=0
    
    # We only absolutely need grep and sed, which should be available on any Unix system
    for cmd in grep sed; do
        if ! command_exists "$cmd"; then
            echo -e "${RED}Required tool '$cmd' is not installed.${NC}"
            missing_tools=1
        fi
    done
    
    if [ $missing_tools -eq 1 ]; then
        die "Please install the missing tools and try again."
    fi
    
    # Check for yq but don't require it
    local yq_type=$(detect_yq_version)
    if [[ "$yq_type" == "none" ]]; then
        echo -e "${YELLOW}Note: 'yq' is not installed. The script will use fallback methods to read/write YAML, which may be less reliable.${NC}"
        echo -e "${BLUE}For better YAML handling, consider installing the Go version of yq:${NC}"
        echo -e "${BLUE}https://github.com/mikefarah/yq/#install${NC}"
    elif [[ "$yq_type" == "python" ]]; then
        echo -e "${YELLOW}Note: You have the Python version of 'yq' installed. The script will attempt to use it, but the Go version is recommended for better compatibility.${NC}"
    elif [[ "$yq_type" == "unknown" ]]; then
        echo -e "${YELLOW}Warning: An unknown version of 'yq' is installed. The script will try to use it but may fall back to other methods.${NC}"
    fi

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
    
    # Update versions in files
    update_versions "$new_version" "$current_version"
    
    # Create an array with the files we know will be updated
    local updated_files=("$CHART_FILE")
    if [ -f "$PYPROJECT_FILE" ]; then
        updated_files+=("$PYPROJECT_FILE")
    fi

    echo
    echo -e "${GREEN}Version updated successfully to $new_version${NC}"

    # Commit changes if enabled
    if [ $COMMIT_CHANGES -eq 1 ]; then
        echo
        echo -e "${BLUE}Committing changes...${NC}"
        # Pass the array of updated files (absolute paths) to the commit function
        create_git_commit "$new_version" "$dry_run" "${updated_files[@]}"
    else
        echo
        echo -e "${YELLOW}Dry run complete or commit disabled. No changes were committed.${NC}"
        if [ ${#updated_files[@]} -gt 0 ]; then
             echo -e "${BLUE}Files updated: ${updated_files[*]}${NC}"
             echo -e "${BLUE}Please review and commit the changes manually.${NC}"
        else
             echo -e "${YELLOW}No files were modified.${NC}"
        fi
    fi

}

# Run main function
main