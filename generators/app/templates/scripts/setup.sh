#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_REPO="https://api.github.com/repos/Scholar-Spark/scholarSparkDevSecrits/contents"
SCRIPT_PATH="scripts/setup.sh"
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
echo -e "${BLUE}Fetching latest setup script...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

# Create temporary file
TMP_SCRIPT=$(mktemp)

# Fetch the script with verbose output for debugging
echo -e "${BLUE}Attempting to fetch from: $SCRIPT_REPO/$SCRIPT_PATH${NC}"
HTTP_RESPONSE=$(curl -sL -w "%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3.raw" \
    "$SCRIPT_REPO/$SCRIPT_PATH" -o "$TMP_SCRIPT")

if [ "$HTTP_RESPONSE" = "200" ]; then
    echo -e "${GREEN}Successfully fetched latest script${NC}"
    chmod +x "$TMP_SCRIPT"
    exec "$TMP_SCRIPT" "$@"
else
    echo -e "${RED}Failed to fetch setup script from repository (HTTP $HTTP_RESPONSE)${NC}"
    echo -e "${RED}URL: $SCRIPT_REPO/$SCRIPT_PATH${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  1. You have access to the Scholar-Spark organization"
    echo -e "  2. The repository and file path are correct"
    cat "$TMP_SCRIPT" # This will show the error message from GitHub
    rm -f "$TMP_SCRIPT"
    exit 1
fi