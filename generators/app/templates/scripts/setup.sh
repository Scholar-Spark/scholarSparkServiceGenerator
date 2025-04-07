#!/bin/bash

# --- Configuration ---
# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set Skaffold project directory to parent of scripts folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SKAFFOLD_PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Repository details
REPO_OWNER="Scholar-Spark"
REPO_NAME="scholarSparkDevSecrits" # Make sure this is the correct name
TARGET_SETUP_SCRIPT_PATH="scripts/setup.sh" # Relative path within the repo

# --- Helper Functions ---

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print error messages and exit
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    # Clean up temporary directory if it exists
    # shellcheck disable=SC2154 # TMP_DIR is defined later or globally
    [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    exit 1
}

# Function to print dependency installation instructions
print_install_instructions() {
    local cmd="$1"
    local install_url="$2"
    echo -e "${YELLOW}Dependency '$cmd' is missing.${NC}"
    echo -e "${BLUE}Please install it using your system's package manager or visit:${NC}"
    echo -e "${GREEN}$install_url${NC}"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo -e "${BLUE}On macOS, you can often use Homebrew: brew install $cmd${NC}"
    elif command_exists apt-get; then
        echo -e "${BLUE}On Debian/Ubuntu, try: sudo apt-get update && sudo apt-get install $cmd${NC}"
    elif command_exists yum; then
        echo -e "${BLUE}On CentOS/Fedora, try: sudo yum install $cmd${NC}"
    elif command_exists pacman; then
        echo -e "${BLUE}On Arch Linux, try: sudo pacman -S $cmd${NC}"
    fi
}

# --- Dependency Checks ---
echo -e "${BLUE}Checking required tools...${NC}"
REQUIRED_COMMANDS=( "gh" "git" "curl" "tar" "mktemp" "skaffold" "kubectl" )
INSTALL_URLS=(
    "https://cli.github.com/manual/installation"
    "https://git-scm.com/downloads"
    "https://curl.se/download.html"
    "https://www.gnu.org/software/tar/"
    "Usually part of coreutils"
    "https://skaffold.dev/docs/install/"
    "https://kubernetes.io/docs/tasks/tools/"
)

dependencies_met=true
for i in "${!REQUIRED_COMMANDS[@]}"; do
    cmd="${REQUIRED_COMMANDS[$i]}"
    url="${INSTALL_URLS[$i]}"
    if ! command_exists "$cmd"; then
        print_install_instructions "$cmd" "$url"
        dependencies_met=false
    fi
done

if [ "$dependencies_met" = false ]; then
    die "Please install the missing dependencies and re-run the script."
fi
echo -e "${GREEN}All required tools are available.${NC}"

# --- Main Script Logic ---

# Save the original project directory
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo -e "${BLUE}Project directory: $PROJECT_DIR${NC}"

# Create a temporary directory securely
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'scholar-spark-setup')
if [ -z "$TMP_DIR" ]; then
    die "Failed to create a temporary directory."
fi
# Ensure cleanup on exit (including errors)
trap 'rm -rf "$TMP_DIR"' EXIT SIGINT SIGTERM

# Ensure GitHub CLI Authentication
echo -e "${BLUE}Checking GitHub CLI authentication...${NC}"
if ! gh auth status > /dev/null 2>&1; then
    echo -e "${YELLOW}GitHub CLI needs authentication.${NC}"
    echo -e "${BLUE}Attempting to initiate GitHub login via browser...${NC}"
    # Use --web for a browser-based flow, add scopes if needed (e.g., -s repo)
    if ! gh auth login --web; then
         die "GitHub CLI authentication failed. Please run 'gh auth login' manually and try again."
    fi
    # Re-check status after login attempt
    if ! gh auth status > /dev/null 2>&1; then
        die "GitHub CLI authentication still not successful after login attempt."
    fi
    echo -e "${GREEN}GitHub CLI authenticated successfully.${NC}"
else
    echo -e "${GREEN}GitHub CLI is already authenticated.${NC}"
fi

# Clone the repository using GitHub CLI
CLONE_DIR="$TMP_DIR/repo-clone"
mkdir -p "$CLONE_DIR" || die "Failed to create clone directory '$CLONE_DIR'."

echo -e "${BLUE}Downloading Scholar-Spark development scripts from $REPO_OWNER/$REPO_NAME...${NC}"
# Clone quietly unless there's an error
if ! gh repo clone "$REPO_OWNER/$REPO_NAME" "$CLONE_DIR" -- --quiet; then
    # If quiet fails, try verbose for more info
    echo -e "${YELLOW}Initial clone attempt failed, retrying with verbose output...${NC}"
    if ! gh repo clone "$REPO_OWNER/$REPO_NAME" "$CLONE_DIR"; then
        die "GitHub CLI clone failed. Check repository name ('$REPO_NAME'), your access permissions, and network connection."
    fi
fi
echo -e "${GREEN}Repository cloned successfully to temporary location.${NC}"

# Check if the target setup script exists in the cloned repo
SETUP_SCRIPT="$CLONE_DIR/$TARGET_SETUP_SCRIPT_PATH"
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo -e "${RED}Target setup script not found in the repository!${NC}" >&2
    echo -e "${YELLOW}Expected path: '$TARGET_SETUP_SCRIPT_PATH' inside the '$REPO_NAME' repository.${NC}" >&2
    echo -e "${YELLOW}Listing found *.sh files in the cloned repository root:${NC}" >&2
    find "$CLONE_DIR" -maxdepth 1 -type f -name "*.sh" -exec basename {} \; >&2
    die "Cannot proceed without the setup script."
fi

# Make the target script executable
chmod +x "$SETUP_SCRIPT" || die "Failed to make setup script executable: $SETUP_SCRIPT"

# --- Execute Downloaded Script ---
echo -e "${GREEN}Successfully prepared Scholar-Spark development scripts.${NC}"
echo -e "${BLUE}Executing the downloaded setup script: $TARGET_SETUP_SCRIPT_PATH${NC}"
echo -e "${BLUE}------------------------------------------------------${NC}"

# Execute the script from within its directory to handle relative paths correctly
cd "$CLONE_DIR" || die "Failed to change directory to $CLONE_DIR"
# Pass all arguments received by this script to the target script
"$SETUP_SCRIPT" "$@"
EXEC_EXIT_CODE=$?

echo -e "${BLUE}------------------------------------------------------${NC}"

if [ $EXEC_EXIT_CODE -ne 0 ]; then
    # Use die, which will also trigger the trap cleanup
    die "The downloaded setup script ($TARGET_SETUP_SCRIPT_PATH) failed with exit code $EXEC_EXIT_CODE."
else
    echo -e "${GREEN}Downloaded setup script finished successfully.${NC}"
fi

# Explicit exit (trap will clean up)
exit 0