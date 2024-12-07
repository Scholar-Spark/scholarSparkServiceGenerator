#!/bin/bash

# Define the new global npm directory
NPM_GLOBAL_DIR="${HOME}/.npm-global"

# Create the directory if it doesn't exist
if [ ! -d "$NPM_GLOBAL_DIR" ]; then
  echo "Creating npm global directory at $NPM_GLOBAL_DIR"
  mkdir -p "$NPM_GLOBAL_DIR"
fi

# Configure npm to use the new directory
echo "Configuring npm to use the new global directory"
npm config set prefix "$NPM_GLOBAL_DIR"

# Add the new directory to the PATH in the appropriate shell configuration file
SHELL_CONFIG_FILE="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
  SHELL_CONFIG_FILE="$HOME/.zshrc"
fi

# Check if the PATH modification already exists
if ! grep -q "export PATH=\"$NPM_GLOBAL_DIR/bin:\$PATH\"" "$SHELL_CONFIG_FILE"; then
  echo "Adding npm global directory to PATH in $SHELL_CONFIG_FILE"
  echo "export PATH=\"$NPM_GLOBAL_DIR/bin:\$PATH\"" >> "$SHELL_CONFIG_FILE"
else
  echo "npm global directory already in PATH"
fi

# Reload the shell configuration
echo "Reloading shell configuration"
source "$SHELL_CONFIG_FILE"

# Install dependencies and link the package globally
echo "Installing dependencies and linking the package globally"
npm install
npm link

echo "Scholarspark-service-generator is now available globally as 'scholarspark-service'."