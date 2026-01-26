#!/bin/sh
set -e

# Handler installer script
# Usage: curl -fsSL https://handler.dev/install.sh | sh
#
# Environment variables:
#   HANDLER_CHANNEL      - Release channel: stable (default) or nightly
#   HANDLER_VERSION      - Specific version to install (overrides channel)
#   HANDLER_INSTALL_DIR  - Installation directory (default: ~/.local/bin)

REPO="yifever/handler-releases"
CHANNEL="${HANDLER_CHANNEL:-stable}"
VERSION="${HANDLER_VERSION:-}"
INSTALL_DIR="${HANDLER_INSTALL_DIR:-$HOME/.local/bin}"

# Resolve version from channel if not explicitly set
if [ -z "$VERSION" ]; then
  case "$CHANNEL" in
    stable)
      VERSION="latest"
      ;;
    nightly)
      VERSION="nightly"
      ;;
    *)
      echo "Error: Unknown channel '$CHANNEL'. Use 'stable' or 'nightly'."
      exit 1
      ;;
  esac
fi

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  darwin) OS="darwin" ;;
  linux)  OS="linux" ;;
  *)
    echo "Error: Unsupported operating system: $OS"
    exit 1
    ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="x86_64" ;;
  aarch64) ARCH="aarch64" ;;
  arm64)   ARCH="aarch64" ;;  # macOS reports arm64
  *)
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

FILENAME="handler-${OS}-${ARCH}.tar.gz"

# Build download URL
if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$FILENAME"
else
  DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"
fi

echo "Installing Handler..."
echo "  OS: $OS"
echo "  Arch: $ARCH"
echo "  Channel: $CHANNEL"
echo "  Version: $VERSION"
echo "  Install dir: $INSTALL_DIR"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Create temp directory for download
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download and extract
echo "Downloading from $DOWNLOAD_URL..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$FILENAME"; then
  echo ""
  echo "Error: Failed to download Handler."
  echo "Please check that the version exists and your platform is supported."
  echo ""
  echo "Supported platforms:"
  echo "  - macOS (Intel): darwin-x86_64"
  echo "  - macOS (Apple Silicon): darwin-aarch64"
  echo "  - Linux (x64): linux-x86_64"
  echo "  - Linux (ARM64): linux-aarch64"
  exit 1
fi

echo "Extracting..."
tar -xzf "$TMP_DIR/$FILENAME" -C "$TMP_DIR"

# Install binary
mv "$TMP_DIR/handler" "$INSTALL_DIR/handler"
chmod +x "$INSTALL_DIR/handler"

echo ""
echo "Handler installed successfully to $INSTALL_DIR/handler"
echo ""

# Check if install dir is in PATH
case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    echo "Run 'handler' to get started."
    ;;
  *)
    echo "Add $INSTALL_DIR to your PATH to use Handler:"
    echo ""
    echo "  # For bash (add to ~/.bashrc or ~/.bash_profile)"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "  # For zsh (add to ~/.zshrc)"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then run 'handler' to get started."
    ;;
esac
