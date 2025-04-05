#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="Scholar-Spark"
REPO_NAME="scholarSparkDevScripts"
BRANCH="main"  # or whichever branch you want to use
TOKEN_DIR="$HOME/.scholar-spark"
TOKEN_FILE="$TOKEN_DIR/github_token"

# Function to create GitHub token
create_github_token() {
    echo -e "${BLUE}Creating GitHub token for Scholar-Spark development...${NC}"
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}GitHub CLI (gh) not found. Installing...${NC}"
        
        # Install gh CLI based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gh
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Check for common package managers
            if command -v apt-get &> /dev/null; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install gh
            elif command -v dnf &> /dev/null; then
                sudo dnf install 'dnf-command(config-manager)'
                sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                sudo dnf install gh
            else
                echo -e "${RED}Unable to install GitHub CLI. Please install manually: https://github.com/cli/cli#installation${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Unsupported operating system${NC}"
            exit 1
        fi
    fi

    # Ensure gh is logged in
    if ! gh auth status &> /dev/null; then
        echo -e "${BLUE}Please login to GitHub...${NC}"
        gh auth login -s "repo" -w
    fi

    # Create a new token with necessary scopes
    echo -e "${BLUE}Creating new GitHub token...${NC}"
    TOKEN=$(gh auth token)
    
    # Save token
    mkdir -p "$TOKEN_DIR"
    echo "$TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    
    echo -e "${GREEN}Successfully created and stored GitHub token${NC}"
    return 0
}

# Function to get GitHub token
get_github_token() {
    # Check if token exists and is valid
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(cat "$TOKEN_FILE")
        # Verify token is valid
        if curl -s -H "Authorization: token $TOKEN" https://api.github.com/user &> /dev/null; then
            echo "$TOKEN"
            return 0
        fi
    fi
    
    # If we get here, we need to create a new token
    create_github_token
    cat "$TOKEN_FILE"
}

# Get or create GitHub token
GITHUB_TOKEN=$(get_github_token)
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}Failed to obtain GitHub token${NC}"
    exit 1
fi

# Fetch and execute the main script
echo -e "${BLUE}Downloading Scholar-Spark development scripts...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

# Create a temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Download the repository archive
ARCHIVE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/tarball/$BRANCH"
ARCHIVE_FILE="$TMP_DIR/repo.tar.gz"

echo -e "${BLUE}Downloading from: $ARCHIVE_URL${NC}"
HTTP_RESPONSE=$(curl -sL -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3.raw" \
    "$ARCHIVE_URL" -o "$ARCHIVE_FILE")

if [ "$HTTP_RESPONSE" != "200" ]; then
    echo -e "${RED}Failed to download repository archive (HTTP $HTTP_RESPONSE)${NC}"
    echo -e "${RED}URL: $ARCHIVE_URL${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  1. You have access to the Scholar-Spark organization"
    echo -e "  2. The repository and branch names are correct"
    cat "$ARCHIVE_FILE" # This will show the error message from GitHub
    rm -f "$ARCHIVE_FILE"
    exit 1
fi

# Extract the archive
echo -e "${BLUE}Extracting scripts...${NC}"
if ! tar -xzf "$ARCHIVE_FILE" -C "$TMP_DIR"; then
    echo -e "${RED}Failed to extract repository archive${NC}"
    exit 1
fi

# Find the extracted directory (GitHub adds a prefix with owner-repo-commit)
EXTRACT_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "$REPO_OWNER-$REPO_NAME-*" | head -n 1)

if [ -z "$EXTRACT_DIR" ]; then
    echo -e "${RED}Failed to locate extracted repository${NC}"
    exit 1
fi

# Check if setup script exists
SETUP_SCRIPT="$EXTRACT_DIR/scripts/setup.sh"
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo -e "${RED}Setup script not found in the repository${NC}"
    echo -e "${YELLOW}Expected path: $SETUP_SCRIPT${NC}"
    echo -e "${YELLOW}Available files:${NC}"
    find "$EXTRACT_DIR" -type f -name "*.sh" | sort
    exit 1
fi

# Make the script executable
chmod +x "$SETUP_SCRIPT"

# Print success message
echo -e "${GREEN}Successfully downloaded Scholar-Spark development scripts${NC}"
echo -e "${BLUE}Executing setup script...${NC}"

# Execute the setup script with all original arguments
exec "$SETUP_SCRIPT" "$@"