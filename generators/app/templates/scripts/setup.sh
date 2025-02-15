#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add this function near the top of the file, after the color definitions
print_logo() {
    clear
    echo -e "${BLUE}
   _____ _           _             _____                  _    
  / ____| |         | |           / ____|                | |   
 | (___ | |__   ___ | | __ _ _ __| (___  _ __   __ _ _ __| | __
  \___ \| '_ \ / _ \| |/ _\` | '__\___ \| '_ \ / _\` | '__| |/ /
  ____) | | | | (_) | | (_| | |  ____) | |_) | (_| | |  |   < 
 |_____/|_| |_|\___/|_|\__,_|_| |_____/| .__/ \__,_|_|  |_|\_\\
                                        | |                    
                                        |_|                    
${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${YELLOW}    Scholar Spark Development Environment Setup${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

# Function to cleanup resources
cleanup() {
    echo -e "\n🧹 ${BLUE}Cleaning up resources...${NC}"
    
    # Set default namespace if manifest doesn't exist
    NAMESPACE="${ORGANIZATION_PREFIX:-default}-${ENVIRONMENT:-dev}"
    
    # Try to get namespace from manifest if it exists and yq is available
    if [ -f "$HOME/.scholar-spark/manifest/manifest.yaml" ] && command -v yq &>/dev/null; then
        TEMP_NAMESPACE=$(yq '.dev-environment.namespace' "$HOME/.scholar-spark/manifest/manifest.yaml" 2>/dev/null)
        if [ ! -z "$TEMP_NAMESPACE" ] && [ "$TEMP_NAMESPACE" != "null" ]; then
            NAMESPACE="$TEMP_NAMESPACE"
        fi
    fi
    
    # Delete namespace if it exists
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo -e "🗑️  ${BLUE}Deleting namespace $NAMESPACE...${NC}"
        kubectl delete namespace "$NAMESPACE" --timeout=2m || {
            echo -e "${YELLOW}Force deleting namespace...${NC}"
            kubectl delete namespace "$NAMESPACE" --force --grace-period=0
        }
    fi
    
    # Stop minikube if it's running
    if minikube status &>/dev/null; then
        echo -e "🛑 ${BLUE}Stopping minikube cluster...${NC}"
        minikube stop
    fi
    
    echo -e "✨ ${GREEN}Cleanup completed${NC}"
}

# Function to handle script interruption
handle_interrupt() {
    echo -e "\n\n⚠️  ${YELLOW}Script interrupted. Cleaning up...${NC}"
    cleanup
    exit 1
}

# Register the interrupt handler
trap handle_interrupt SIGINT SIGTERM

# Function to get project name from pyproject.toml
get_project_name() {
    if [[ -f "pyproject.toml" ]]; then
        # Extract name from pyproject.toml using grep and cut
        PROJECT_NAME=$(grep '^name = ' pyproject.toml | cut -d'"' -f2 || echo "")
        if [[ -n "$PROJECT_NAME" ]]; then
            echo "$PROJECT_NAME"
            return 0
        fi
    fi
    
    echo -e "${RED}Error: Could not find project name in pyproject.toml${NC}"
    echo -e "${YELLOW}Please ensure you're in the project root directory with a valid pyproject.toml${NC}"
    exit 1
}

# Get service name from pyproject.toml
SERVICE_NAME=$(get_project_name)
echo -e "${BLUE}Detected service: ${SERVICE_NAME}${NC}"

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Get OS type
OS=$(detect_os)

# Function to install dependencies based on OS
install_dependencies() {
    local os=$1
    echo -e "${BLUE}Installing dependencies for $os...${NC}"
    
    case $os in
        "macos")
            if ! command -v brew &> /dev/null; then
                echo -e "${YELLOW}Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install yq minikube kubectl skaffold helm
            ;;
            
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get install -y curl wget apt-transport-https
            
            # Install yq
            echo -e "${YELLOW}Installing yq...${NC}"
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod a+x /usr/local/bin/yq
            
            # Install Helm
            curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
            sudo apt-get update
            sudo apt-get install -y helm
            
            # Install minikube
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
            
            # Install kubectl
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install kubectl /usr/local/bin/kubectl
            rm kubectl
            
            # Install Skaffold
            curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
            sudo install skaffold /usr/local/bin/
            rm skaffold
            ;;
            
        "fedora"|"rhel"|"centos")
            sudo dnf install -y curl wget
            
            # Install yq
            echo -e "${YELLOW}Installing yq...${NC}"
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod a+x /usr/local/bin/yq
            
            # Install Helm
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            
            # Install minikube
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
            
            # Install kubectl
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install kubectl /usr/local/bin/kubectl
            rm kubectl
            
            # Install Skaffold
            curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
            sudo install skaffold /usr/local/bin/
            rm skaffold
            ;;
            
        "arch"|"manjaro")
            sudo pacman -Sy --noconfirm curl wget yq minikube kubectl helm
            ;;

        "nixos")
            # For NixOS, we'll guide users to add these to their configuration
            echo -e "${YELLOW}For NixOS, please add the following to your configuration.nix:${NC}"
            echo -e "
environment.systemPackages = with pkgs; [
  docker
  kubectl
  minikube
  skaffold
  helm
];

virtualisation.docker.enable = true;
"
            echo -e "${YELLOW}Then run: sudo nixos-rebuild switch${NC}"
            read -p "Press Enter once you've updated your NixOS configuration..."
            
            # Verify installations
            if ! command -v docker &> /dev/null || \
               ! command -v kubectl &> /dev/null || \
               ! command -v minikube &> /dev/null || \
               ! command -v skaffold &> /dev/null || \
               ! command -v helm &> /dev/null; then
                echo -e "${RED}Some required tools are missing. Please ensure they are added to your NixOS configuration.${NC}"
                exit 1
            fi
            ;;
            
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            exit 1
            ;;
    esac
}

# Check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker daemon is not running. Please start Docker first.${NC}"
        exit 1
    fi
}

# Function to get service URL
get_service_url() {
    local retries=0
    local max_retries=30
    local service_url=""

    echo -e "${BLUE}Waiting for service URL...${NC}"
    
    while [ $retries -lt $max_retries ]; do
        service_url=$(minikube service ${SERVICE_NAME} -n scholar-spark-dev --url 2>/dev/null)
        if [ -n "$service_url" ]; then
            echo "$service_url"
            return 0
        fi
        retries=$((retries + 1))
        sleep 2
        echo -n "."
    done
    
    echo -e "\n${RED}Could not get service URL. Using localhost:8000 as fallback${NC}"
    echo "http://localhost:8000"
}

# Function to print developer-friendly information
print_dev_info() {
    clear
    echo -e "\n🎉 ${GREEN}Scholar Spark Development Environment is Ready!${NC}\n"
    echo -e "📦 ${BLUE}Service: ${GREEN}${SERVICE_NAME}${NC}\n"
    echo -e "🔗 ${BLUE}API Endpoints:${NC}"
    echo -e "   ${GREEN}→ API:     \033]8;;${SERVICE_URL}${API_PATH:-/api/v1}\033\\${SERVICE_URL}${API_PATH:-/api/v1}\033]8;;\033\\"
    echo -e "   → Docs:    \033]8;;${SERVICE_URL}/docs\033\\${SERVICE_URL}/docs\033]8;;\033\\"
    echo -e "   → Health:  \033]8;;${SERVICE_URL}/health\033\\${SERVICE_URL}/health\033]8;;\033\\${NC}\n"
    echo -e "📝 ${BLUE}Development Tips:${NC}"
    echo -e "   ${GREEN}→ Your code changes will automatically reload"
    echo -e "   → API docs are always up-to-date at /docs"
    echo -e "   → Logs will appear below${NC}\n"
    echo -e "🛠️  ${BLUE}Useful Commands:${NC}"
    echo -e "   ${GREEN}→ CTRL+C to stop the service"
    echo -e "   → ./scripts/dev.sh to restart${NC}\n"
    echo -e "📊 ${BLUE}Monitoring:${NC}"
    echo -e "   ${GREEN}→ Traces: \033]8;;${TRACES_ENDPOINT:-http://localhost:3200}\033\\${TRACES_ENDPOINT:-http://localhost:3200}\033]8;;\033\\"
    echo -e "   → Logs:   \033]8;;${LOGS_ENDPOINT:-http://localhost:3100}\033\\${LOGS_ENDPOINT:-http://localhost:3100}\033]8;;\033\\${NC}\n"
    echo -e "${YELLOW}Starting development server...${NC}\n"
}

# Function to setup Helm registry authentication
setup_helm_registry() {
    echo -e "${BLUE}Setting up Helm registry authentication...${NC}"
    
    # Check for required tools
    for cmd in gh jq; do
        if ! command -v $cmd &> /dev/null; then
            case $cmd in
                gh)
                    echo -e "${YELLOW}Installing GitHub CLI...${NC}"
                    case $OS in
                        "macos")
                            brew install gh
                            ;;
                        "ubuntu"|"debian")
                            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                            sudo apt update
                            sudo apt install -y gh
                            ;;
                        "fedora"|"rhel"|"centos")
                            sudo dnf install -y gh
                            ;;
                        "arch"|"manjaro")
                            sudo pacman -S --noconfirm github-cli
                            ;;
                    esac
                    ;;
                jq)
                    echo -e "${YELLOW}Installing jq...${NC}"
                    case $OS in
                        "macos")
                            brew install jq
                            ;;
                        "ubuntu"|"debian")
                            sudo apt update && sudo apt install -y jq
                            ;;
                        "fedora"|"rhel"|"centos")
                            sudo dnf install -y jq
                            ;;
                        "arch"|"manjaro")
                            sudo pacman -S --noconfirm jq
                            ;;
                    esac
                    ;;
            esac
        fi
    done

    # GitHub login if not already authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}Please login to GitHub...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]] || [ -n "$DISPLAY" ]; then
            gh auth login --git-protocol ssh --web
        else
            echo -e "${YELLOW}Please visit https://github.com/login/device in your browser${NC}"
            gh auth login --git-protocol ssh --web
        fi
    fi

    # Get GitHub token
    GITHUB_USER=$(gh api user | jq -r .login)
    echo -e "${GREEN}Authenticated as: ${GITHUB_USER}${NC}"
    
    TOKEN=$(gh auth token)
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}Failed to get GitHub token${NC}"
        exit 1
    fi

    # Login to Helm registry
    echo -e "${BLUE}Logging into Helm registry...${NC}"
    if ! helm registry login ghcr.io -u "$GITHUB_USER" -p "$TOKEN"; then
        echo -e "${RED}Failed to login to Helm registry${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Successfully authenticated with Helm registry${NC}"
}

# Function to clone/update manifest repository
setup_manifest() {
    echo -e "${BLUE}Setting up development manifest...${NC}"
    
    MANIFEST_DIR="$HOME/.scholar-spark/manifest"
    # Fix typo in URL (remove extra 't')
    MANIFEST_REPO="${DEV_MANIFEST_REPO:-https://github.com/Scholar-Spark/scholarSparkServiceGenerator}"
    
    if [ -z "$DEV_MANIFEST_REPO" ]; then
        echo -e "${YELLOW}Warning: DEV_MANIFEST_REPO not set, using default repository${NC}"
    fi
    
    # Check if directory exists and is a valid git repository
    if [ -d "$MANIFEST_DIR/.git" ] && git -C "$MANIFEST_DIR" rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${BLUE}Updating manifest repository...${NC}"
        if ! git -C "$MANIFEST_DIR" pull; then
            echo -e "${YELLOW}Failed to update repository, attempting to re-clone...${NC}"
            rm -rf "$MANIFEST_DIR"
            mkdir -p "$MANIFEST_DIR"
            git clone "$MANIFEST_REPO" "$MANIFEST_DIR" || {
                echo -e "${RED}Failed to clone manifest repository${NC}"
                exit 1
            }
        fi
    else
        # Directory doesn't exist or is not a valid git repo
        echo -e "${BLUE}Cloning manifest repository...${NC}"
        rm -rf "$MANIFEST_DIR"  # Clean up any existing invalid directory
        mkdir -p "$MANIFEST_DIR"
        git clone "$MANIFEST_REPO" "$MANIFEST_DIR" || {
            echo -e "${RED}Failed to clone manifest repository${NC}"
            exit 1
        }
    fi
    
    echo -e "${GREEN}Successfully setup manifest${NC}"
}

# Function to verify yq installation
verify_yq() {
    # Find yq location
    YQ_PATH=$(which yq 2>/dev/null)
    
    # Force reinstall yq
    echo -e "${YELLOW}Installing/Updating yq...${NC}"
    case $OS in
        "ubuntu"|"debian")
            sudo rm -f /usr/local/bin/yq
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64
            sudo chmod a+x /usr/local/bin/yq
            YQ_PATH="/usr/local/bin/yq"
            ;;
        "macos")
            brew reinstall yq
            YQ_PATH=$(which yq)
            ;;
        "fedora"|"rhel"|"centos")
            sudo rm -f /usr/local/bin/yq
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64
            sudo chmod a+x /usr/local/bin/yq
            YQ_PATH="/usr/local/bin/yq"
            ;;
        "arch"|"manjaro")
            sudo pacman -Sy --noconfirm yq
            YQ_PATH=$(which yq)
            ;;
    esac
    
    # Verify installation
    if ! $YQ_PATH --version &>/dev/null; then
        echo -e "${RED}Failed to install yq${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Using yq at: $YQ_PATH${NC}"
    $YQ_PATH --version
    
    # Test yq with a simple YAML parse
    echo "test: value" | $YQ_PATH '.test' > /dev/null || {
        echo -e "${RED}yq installation is not working correctly${NC}"
        exit 1
    }
    
    # Export YQ_PATH for use in other functions
    export YQ_PATH
    
    echo -e "${GREEN}yq test successful${NC}"
}

# Function to apply manifest configuration
apply_manifest() {
    echo -e "\n📦 ${BLUE}Applying manifest configuration...${NC}"
    
    MANIFEST_DIR="$HOME/.scholar-spark/manifest"
    MANIFEST_FILE="$MANIFEST_DIR/manifest.yaml"
    
    # Verify manifest file exists
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo -e "${RED}Manifest file not found at $MANIFEST_FILE${NC}"
        exit 1
    fi
    
    echo -e "🔍 ${BLUE}Reading manifest configuration...${NC}"
    
    # Create a temporary file for the processed manifest
    TMP_MANIFEST=$(mktemp)
    
    # Replace variables in manifest
    sed -e "s/\${environment}/development/g" \
        -e "s/\${organisation}/scholar-spark/g" \
        "$MANIFEST_FILE" > "$TMP_MANIFEST"
    
    echo -e "📄 ${BLUE}Processed manifest content:${NC}"
    cat "$TMP_MANIFEST"
    
    # Validate manifest structure
    if ! $YQ_PATH -r '.' "$TMP_MANIFEST" > /dev/null 2>&1; then
        echo -e "${RED}Invalid YAML structure in manifest file${NC}"
        rm -f "$TMP_MANIFEST"
        exit 1
    fi
    
    # Parse namespace from manifest
    echo -e "\n🔍 ${BLUE}Parsing namespace...${NC}"
    NAMESPACE=$($YQ_PATH -r '.["dev-environment"].namespace' "$TMP_MANIFEST")
    echo -e "📍 ${BLUE}Using namespace: $NAMESPACE${NC}"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "🔧 ${BLUE}Creating namespace: $NAMESPACE${NC}"
        kubectl create namespace "$NAMESPACE"
    fi
    
    # Install shared infrastructure charts
    echo -e "🚀 ${BLUE}Installing shared infrastructure...${NC}"
    
    echo -e "🔍 ${BLUE}Parsing chart details...${NC}"
    CHART_REPO=$($YQ_PATH -r '.["shared-infrastructure"].charts[0].repository' "$TMP_MANIFEST")
    CHART_VERSION=$($YQ_PATH -r '.["shared-infrastructure"].charts[0].version' "$TMP_MANIFEST")
    CHART_NAME=$($YQ_PATH -r '.["shared-infrastructure"].charts[0].name' "$TMP_MANIFEST")
    
    # Verify values exist
    if [ -z "$CHART_REPO" ] || [ -z "$CHART_VERSION" ] || [ -z "$CHART_NAME" ]; then
        echo -e "${RED}Failed to parse chart information. Please check the manifest structure${NC}"
        rm -f "$TMP_MANIFEST"
        exit 1
    fi
    
    echo -e "📥 ${BLUE}Pulling chart: $CHART_NAME (version $CHART_VERSION)${NC}"
    echo -e "   ${BLUE}From: $CHART_REPO${NC}"
    
    # Pull chart with explicit output file
    CHART_FILE="$CHART_NAME-$CHART_VERSION.tgz"
    if ! helm pull "$CHART_REPO/$CHART_NAME" --version "$CHART_VERSION" --destination . ; then
        echo -e "${RED}Failed to pull chart from repository${NC}"
        rm -f "$TMP_MANIFEST"
        exit 1
    fi
    
    # Extract values from manifest and create temporary values file
    TMP_VALUES=$(mktemp)
    $YQ_PATH -r '.["shared-infrastructure"].charts[0].values' "$TMP_MANIFEST" > "$TMP_VALUES"
    
    echo -e "⚙️  ${BLUE}Installing chart with custom values...${NC}"
    
    # Install/upgrade the chart
    helm upgrade --install "$CHART_NAME" "./$CHART_FILE" \
        --namespace "$NAMESPACE" \
        --values "$TMP_VALUES" \
        --timeout 10m \
        --wait \
        --debug || {
        echo -e "${RED}Failed to install chart${NC}"
        rm -f "$TMP_VALUES"
        rm -f "$TMP_MANIFEST"
        rm -f "./$CHART_FILE"
        exit 1
    }
    
    # Cleanup
    rm -f "$TMP_VALUES"
    rm -f "$TMP_MANIFEST"
    rm -f "./$CHART_FILE"
    
    echo -e "✅ ${GREEN}Successfully applied manifest configuration${NC}"
}

# Function to handle Docker config issues
handle_docker_config() {
    echo -e "${YELLOW}Docker config issue detected. Attempting to fix...${NC}"
    
    # Backup existing config if it exists
    if [ -f "$HOME/.docker/config.json" ]; then
        echo -e "${BLUE}Backing up existing Docker config...${NC}"
        cp "$HOME/.docker/config.json" "$HOME/.docker/config.json.backup-$(date +%Y%m%d-%H%M%S)"
        
        # Remove corrupted config
        echo -e "${BLUE}Removing corrupted Docker config...${NC}"
        rm "$HOME/.docker/config.json"
        
        # Restart Docker if possible
        if command -v systemctl &> /dev/null && systemctl is-active docker &> /dev/null; then
            echo -e "${BLUE}Restarting Docker service...${NC}"
            sudo systemctl restart docker
        fi
    fi
}

# Function to load environment variables
load_env_vars() {
    if [ ! -f .env ]; then
        echo -e "${RED}Error: No .env file found. Please create one based on .env.example${NC}"
        exit 1
    fi
    
    # Safer env loading with error checking
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] || [ -z "$key" ] && continue
        # Trim whitespace and quotes
        value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["\x27]//' -e 's/["\x27]$//')
        export "$key=$value"
    done < .env
}

# Main setup process
main() {
    print_logo
    trap handle_interrupt SIGINT SIGTERM

    # Phase 1: System Verification
    echo -e "${BLUE}${BOLD}Phase 1: System Verification${NC}"
    SERVICE_NAME=$(get_project_name)
    
    # Detect OS
    OS=$(detect_os)
    echo -e "${BLUE}Detected OS: $OS${NC}"
    
    # Load environment variables from .env file
    load_env_vars

    # Verify yq installation before proceeding
    verify_yq || {
        echo -e "${RED}Failed to verify yq installation${NC}"
        exit 1
    }

    # Perform initial cleanup
    echo -e "\n🧹 ${BLUE}Performing initial cleanup...${NC}"
    cleanup

    echo -e "${BLUE}Setting up development environment...${NC}"

    # Start minikube if not running
    if ! minikube status &> /dev/null; then
        echo -e "${BLUE}Starting Minikube...${NC}"
        if ! minikube start \
            --driver=docker \
            --docker-opt dns=8.8.8.8 \
            --docker-opt dns=8.8.4.4 \
            --insecure-registry "10.0.0.0/24" \
            --registry-mirror=https://mirror.gcr.io \
            --registry-mirror=https://registry-1.docker.io; then
            
            handle_docker_config
            echo -e "${BLUE}Retrying Minikube start...${NC}"
            minikube start \
                --driver=docker \
                --docker-opt dns=8.8.8.8 \
                --docker-opt dns=8.8.4.4 \
                --insecure-registry "10.0.0.0/24" \
                --registry-mirror=https://mirror.gcr.io \
                --registry-mirror=https://registry-1.docker.io || {
                echo -e "${RED}Failed to start Minikube${NC}"
                exit 1
            }
        fi
    fi

    # Configure Docker to use minikube's Docker daemon
    echo -e "${BLUE}Configuring Docker environment...${NC}"
    eval $(minikube docker-env)

    # Setup Helm registry and manifest
    setup_helm_registry
    setup_manifest
    
    # Apply manifest configuration
    apply_manifest

    # Start skaffold in development mode
    echo -e "${BLUE}Starting Skaffold...${NC}"
    skaffold dev --port-forward
}

# Run main function
main

