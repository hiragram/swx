#!/bin/bash
set -e

# swx installer
# Usage: curl -fsSL https://raw.githubusercontent.com/hiragram/swx/main/install.sh | bash

REPO="hiragram/swx"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Installing swx..."

# Check for required tools
if ! command -v git &> /dev/null; then
    echo "Error: git is required but not installed."
    exit 1
fi

if ! command -v swift &> /dev/null; then
    echo "Error: swift is required but not installed."
    echo "Install Xcode or Swift toolchain from https://swift.org/download/"
    exit 1
fi

# Clone repository
echo "Cloning repository..."
git clone --depth 1 "https://github.com/${REPO}.git" "$TMP_DIR/swx" 2>&1

# Build
echo "Building..."
cd "$TMP_DIR/swx"
swift build -c release 2>&1

# Install
echo "Installing to ${INSTALL_DIR}..."
if [ -w "$INSTALL_DIR" ]; then
    cp ".build/release/swx" "$INSTALL_DIR/"
else
    echo "Need sudo to install to ${INSTALL_DIR}"
    sudo cp ".build/release/swx" "$INSTALL_DIR/"
fi

echo ""
echo "swx installed successfully!"
echo ""
echo "Usage:"
echo "  swx owner/repo            # Run a Swift package"
echo "  swx owner/repo@v1.0.0     # Run a specific version"
echo "  swx owner/repo -- --help  # Pass arguments to the executable"
