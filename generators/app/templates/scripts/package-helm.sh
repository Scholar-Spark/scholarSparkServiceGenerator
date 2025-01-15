#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHART_NAME="<%= name %>"
CHART_VERSION=$(yq eval '.version' helm/Chart.yaml)
REGISTRY="${HELM_REGISTRY:-harbor.scholar-spark.dev}"
REGISTRY_USER="${HELM_REGISTRY_USER:-}"
REGISTRY_PASSWORD="${HELM_REGISTRY_PASSWORD:-}"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is required but not installed.${NC}"
        exit 1
    fi
}

# Check required commands
check_command "helm"
check_command "yq"

# Function to package and push Helm chart
package_and_push_chart() {
    echo -e "${BLUE}Packaging Helm chart...${NC}"
    
    # Package the chart
    helm package helm/ || {
        echo -e "${RED}Failed to package Helm chart${NC}"
        exit 1
    }
    
    # Check if registry credentials are provided
    if [ -n "$REGISTRY_USER" ] && [ -n "$REGISTRY_PASSWORD" ]; then
        echo -e "${BLUE}Logging into Helm registry...${NC}"
        echo "$REGISTRY_PASSWORD" | helm registry login "$REGISTRY" --username "$REGISTRY_USER" --password-stdin || {
            echo -e "${RED}Failed to login to Helm registry${NC}"
            exit 1
        }
    fi
    
    # Push the chart
    echo -e "${BLUE}Pushing Helm chart to registry...${NC}"
    helm push "${CHART_NAME}-${CHART_VERSION}.tgz" "oci://${REGISTRY}/charts" || {
        echo -e "${RED}Failed to push Helm chart${NC}"
        exit 1
    }
    
    # Cleanup
    rm "${CHART_NAME}-${CHART_VERSION}.tgz"
    
    echo -e "${GREEN}Successfully packaged and pushed Helm chart${NC}"
    echo -e "${GREEN}Chart: ${REGISTRY}/charts/${CHART_NAME}:${CHART_VERSION}${NC}"
}

# Main execution
echo -e "${BLUE}Starting Helm chart packaging process...${NC}"
echo -e "${BLUE}Chart: ${CHART_NAME}${NC}"
echo -e "${BLUE}Version: ${CHART_VERSION}${NC}"
echo -e "${BLUE}Registry: ${REGISTRY}${NC}"

# Execute packaging and pushing
package_and_push_chart