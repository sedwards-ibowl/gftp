#!/bin/bash
#
# build_gftp_simple.sh - Simple gFTP build using Homebrew GTK3
#
# This script builds gFTP and installs it locally for testing.
# No app bundle creation - just a working gFTP installation.
#

set -e  # Exit on error

# Configuration
HOMEBREW_PREFIX="$(brew --prefix)"
GFTP_PREFIX="${GFTP_PREFIX:-$HOME/gftp-install}"
GFTP_SOURCE="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to clean up build artifacts
clean() {
    echo -e "${YELLOW}Cleaning up build artifacts...${NC}"
    rm -rf "$GFTP_SOURCE/build"
    rm -rf "$GFTP_PREFIX"
    rm -f "$HOME/.local/bin/gftp-gtk"
    rm -f "$HOME/.local/bin/gftp-text"
    echo -e "${GREEN}✓ Clean up complete.${NC}"
    exit 0
}

# Check for 'clean' argument
if [ "$1" == "clean" ]; then
    clean
fi

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  gFTP Simple Build (Homebrew GTK)${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! pkg-config --exists gtk+-3.0; then
    echo -e "${RED}Error: GTK3 not found. Installing...${NC}"
    brew install gtk+3
fi

GTK_VERSION=$(pkg-config --modversion gtk+-3.0)
echo "  ✓ GTK3 version: $GTK_VERSION"

if ! command -v meson &> /dev/null; then
    echo "  Installing meson..."
    brew install meson
fi

if ! command -v ninja &> /dev/null; then
    echo "  Installing ninja..."
    brew install ninja
fi

echo ""

# Set up environment
echo -e "${YELLOW}Setting up build environment...${NC}"

export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig:$HOMEBREW_PREFIX/opt/libffi/lib/pkgconfig"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

echo "  Install prefix: $GFTP_PREFIX"
echo ""

# Clean previous build
if [ -d "$GFTP_SOURCE/build" ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    rm -rf "$GFTP_SOURCE/build"
fi

# Configure
echo -e "${YELLOW}Configuring with meson...${NC}"
cd "$GFTP_SOURCE"

meson setup build \
    --prefix="$GFTP_PREFIX" \
    --buildtype=release \
    -Dgtk_version=3

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Configuration failed${NC}"
    exit 1
fi

echo ""

# Build
echo -e "${YELLOW}Building...${NC}"
meson compile -C build

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Build failed${NC}"
    exit 1
fi

echo ""

# Install
echo -e "${YELLOW}Installing...${NC}"
meson install -C build

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Installation failed${NC}"
    exit 1
fi

echo ""

# Install gftp-text to ~/.local/bin
if [ -f "build/src/text/gftp-text" ]; then
    echo -e "${YELLOW}Installing gftp-text...${NC}"
    mkdir -p "$HOME/.local/bin"
    cp "build/src/text/gftp-text" "$HOME/.local/bin/gftp-text"
    chmod +x "$HOME/.local/bin/gftp-text"
    echo -e "${GREEN}  ✓ Installed to $HOME/.local/bin/gftp-text${NC}"
fi

echo ""

# Create launcher script
echo -e "${YELLOW}Creating launcher script...${NC}"

LAUNCHER="$HOME/.local/bin/gftp-gtk"
cat > "$LAUNCHER" << 'LAUNCHEREOF'
#!/bin/bash
# gFTP GTK launcher script

# Set up environment
export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"
export XDG_DATA_DIRS="$(brew --prefix)/share:$HOME/gftp-install/share:$XDG_DATA_DIRS"

# Run gFTP
exec "$HOME/gftp-install/bin/gftp-gtk" "$@"
LAUNCHEREOF

chmod +x "$LAUNCHER"
echo -e "${GREEN}  ✓ Created launcher at $LAUNCHER${NC}"

echo ""

# Summary
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}     Build Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Installation:${NC}"
echo "  gFTP GTK: $GFTP_PREFIX/bin/gftp-gtk"
echo "  gFTP Text: $HOME/.local/bin/gftp-text"
echo "  Launcher: $HOME/.local/bin/gftp-gtk"
echo ""
echo -e "${BLUE}To run gFTP GTK:${NC}"
echo "  $HOME/.local/bin/gftp-gtk"
echo ""
echo -e "${BLUE}Or directly:${NC}"
echo "  $GFTP_PREFIX/bin/gftp-gtk"
echo ""
echo -e "${BLUE}To run gFTP Text:${NC}"
echo "  gftp-text"
echo ""
echo -e "${BLUE}Add to PATH (optional):${NC}"
echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
echo "  source ~/.zshrc"
echo ""
echo -e "${BLUE}Build info:${NC}"
echo "  GTK: $(pkg-config --modversion gtk+-3.0)"
echo "  GLib: $(pkg-config --modversion glib-2.0)"
echo "  Source: $GFTP_SOURCE"
echo "  Prefix: $GFTP_PREFIX"
echo ""
