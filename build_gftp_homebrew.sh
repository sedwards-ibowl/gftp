#!/bin/bash
#
# build_gftp_homebrew.sh - Build gFTP using Homebrew GTK3 and create macOS app bundle
#
# This script:
# 1. Builds gFTP with meson using Homebrew's GTK3
# 2. Installs to a local prefix
# 3. Creates relocatable app bundle with all dependencies
#
# Requirements:
# - Homebrew with gtk+3 installed (brew install gtk+3)
# - AppBundleGenerator tool
# - meson, ninja
#

set -e  # Exit on error

# Configuration
HOMEBREW_PREFIX="$(brew --prefix)"
GFTP_PREFIX="${GFTP_PREFIX:-$HOME/gftp-install}"
GFTP_SOURCE="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE_GENERATOR="${APP_BUNDLE_GENERATOR:-$HOME/source/AppBundleGenerator/AppBundleGenerator}"
DEST_DIR="${DEST_DIR:-$HOME/Desktop}"
APP_NAME="gFTP"
BUNDLE_ID="org.gftp.gftp-gtk"
VERSION="2.9.1b"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  gFTP macOS Builder (Homebrew)${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Homebrew prefix: $HOMEBREW_PREFIX"
echo "  gFTP install prefix: $GFTP_PREFIX"
echo "  Source directory: $GFTP_SOURCE"
echo "  AppBundleGenerator: $APP_BUNDLE_GENERATOR"
echo "  Destination: $DEST_DIR"
echo "  Bundle identifier: $BUNDLE_ID"
echo "  Version: $VERSION"
echo ""

# Step 0: Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check for GTK3
if ! pkg-config --exists gtk+-3.0; then
    echo -e "${RED}Error: GTK3 not found. Please install with:${NC}"
    echo "  brew install gtk+3"
    exit 1
fi

GTK_VERSION=$(pkg-config --modversion gtk+-3.0)
echo "  ✓ GTK3 version: $GTK_VERSION"

# Check for meson
if ! command -v meson &> /dev/null; then
    echo -e "${RED}Error: meson not found. Installing...${NC}"
    brew install meson
fi

# Check for ninja
if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Error: ninja not found. Installing...${NC}"
    brew install ninja
fi

# Check for AppBundleGenerator (optional)
if [ ! -f "$APP_BUNDLE_GENERATOR" ]; then
    echo -e "${YELLOW}Warning: AppBundleGenerator not found at: $APP_BUNDLE_GENERATOR${NC}"
    echo "  App bundle creation will be skipped."
    echo "  To build it: cd ~/source/AppBundleGenerator && make"
    CREATE_BUNDLE=false
else
    echo "  ✓ AppBundleGenerator found"
    CREATE_BUNDLE=true
fi

echo -e "${GREEN}✓ All required prerequisites found${NC}"
echo ""

# Step 1: Set up environment for Homebrew GTK
echo -e "${YELLOW}Step 1: Setting up build environment...${NC}"

export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig:$HOMEBREW_PREFIX/opt/libffi/lib/pkgconfig"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export CFLAGS="-I$HOMEBREW_PREFIX/include"
export LDFLAGS="-L$HOMEBREW_PREFIX/lib"

# Create install prefix
mkdir -p "$GFTP_PREFIX"

echo "  PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
echo "  PREFIX: $GFTP_PREFIX"
echo ""

# Step 2: Build gFTP
echo -e "${YELLOW}Step 2: Building gFTP...${NC}"

cd "$GFTP_SOURCE"

# Clean previous build
if [ -d "build" ]; then
    echo "  Cleaning previous build..."
    rm -rf build
fi

# Configure with meson
echo "  Configuring with meson..."
meson setup build \
    --prefix="$GFTP_PREFIX" \
    --buildtype=release \
    -Dgtk_version=3

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: meson configuration failed${NC}"
    exit 1
fi

# Build
echo "  Building..."
meson compile -C build

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: build failed${NC}"
    exit 1
fi

# Install
echo "  Installing to $GFTP_PREFIX..."
meson install -C build

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ gFTP built and installed${NC}"
echo ""

# Step 3: Install gftp-text to ~/.local/bin
echo -e "${YELLOW}Step 3: Installing gftp-text...${NC}"

INSTALL_DIR="$HOME/.local/bin"
SOURCE_FILE="build/src/text/gftp-text"
DEST_FILE="$INSTALL_DIR/gftp-text"

if [ -f "$SOURCE_FILE" ]; then
    mkdir -p "$INSTALL_DIR"
    echo "  Installing gftp-text to $DEST_FILE..."
    cp "$SOURCE_FILE" "$DEST_FILE"
    chmod +x "$DEST_FILE"
    echo -e "${GREEN}✓ gftp-text installed${NC}"
else
    echo -e "${YELLOW}  Warning: gftp-text not found at $SOURCE_FILE${NC}"
fi
echo ""

# Step 4: Create .icns file from SVG
echo -e "${YELLOW}Step 4: Creating .icns file from SVG...${NC}"
SVG_ICON="$GFTP_SOURCE/icons/scalable/gftp.svg"
ICNS_FILE="$GFTP_SOURCE/gftp.icns"

if [ -f "$SVG_ICON" ]; then
    echo "  Found SVG icon, converting to ICNS..."
    TEMP_ICONSET=$(mktemp -d)/gftp.iconset
    mkdir -p "$TEMP_ICONSET"

    # Convert SVG to PNG at high resolution
    # Try multiple methods
    TEMP_PNG=""
    
    # Method 1: Try rsvg-convert if available
    if command -v rsvg-convert &> /dev/null; then
        TEMP_PNG="/tmp/gftp_icon.png"
        rsvg-convert -w 1024 -h 1024 "$SVG_ICON" -o "$TEMP_PNG" 2>/dev/null
    # Method 2: Try qlmanage
    elif command -v qlmanage &> /dev/null; then
        qlmanage -t -s 1024 -o /tmp "$SVG_ICON" 2>/dev/null
        TEMP_PNG=$(ls /tmp/gftp.svg.png 2>/dev/null | head -1)
    fi

    if [ -f "$TEMP_PNG" ]; then
        # Generate all required icon sizes
        for size in 16 32 128 256 512; do
            sips -z $size $size "$TEMP_PNG" --out "$TEMP_ICONSET/icon_${size}x${size}.png" >/dev/null 2>&1
            sips -z $((size*2)) $((size*2)) "$TEMP_PNG" --out "$TEMP_ICONSET/icon_${size}x${size}@2x.png" >/dev/null 2>&1
        done

        # Create ICNS file
        iconutil -c icns "$TEMP_ICONSET" -o "$ICNS_FILE"
        if [ -f "$ICNS_FILE" ]; then
            echo -e "${GREEN}  ✓ Icon converted successfully${NC}"
        fi

        # Cleanup
        rm -rf "$(dirname "$TEMP_ICONSET")" "$TEMP_PNG"
    else
        echo -e "${YELLOW}  Warning: Failed to convert SVG icon${NC}"
        ICNS_FILE=""
    fi
else
    echo -e "${YELLOW}  Warning: SVG icon not found${NC}"
    ICNS_FILE=""
fi
echo ""

# Step 5: Create app bundle (if AppBundleGenerator is available)
if [ "$CREATE_BUNDLE" = true ]; then
    echo -e "${YELLOW}Step 5: Creating macOS app bundle...${NC}"

    BUNDLE_ARGS=()
    BUNDLE_ARGS+=("--identifier" "$BUNDLE_ID")
    BUNDLE_ARGS+=("--version" "$VERSION")
    BUNDLE_ARGS+=("--category" "public.app-category.utilities")
    BUNDLE_ARGS+=("--min-os" "11.0")
    BUNDLE_ARGS+=("--sign" "-")
    BUNDLE_ARGS+=("--hardened-runtime")
    BUNDLE_ARGS+=("--allow-dyld-vars")
    
    # Stage dependencies from both gFTP prefix and Homebrew
    BUNDLE_ARGS+=("--stage-dependencies" "$GFTP_PREFIX")
    BUNDLE_ARGS+=("--stage-dependencies" "$HOMEBREW_PREFIX")

    if [ -n "$ICNS_FILE" ] && [ -f "$ICNS_FILE" ]; then
        BUNDLE_ARGS+=("--icon" "$ICNS_FILE")
    fi

    echo "  Running AppBundleGenerator..."
    
    "$APP_BUNDLE_GENERATOR" \
        "${BUNDLE_ARGS[@]}" \
        "$APP_NAME" \
        "$DEST_DIR" \
        "$GFTP_PREFIX/bin/gftp-gtk"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: AppBundleGenerator failed${NC}"
        exit 1
    fi

    BUNDLE_PATH="$DEST_DIR/$APP_NAME.app"
    echo -e "${GREEN}✓ App bundle created${NC}"
    echo ""

    # Step 6: Verify the bundle
    echo -e "${YELLOW}Step 6: Verifying app bundle...${NC}"

    if [ ! -d "$BUNDLE_PATH" ]; then
        echo -e "${RED}Error: Bundle not created at $BUNDLE_PATH${NC}"
        exit 1
    fi

    echo "  Checking bundle structure..."
    if [ -d "$BUNDLE_PATH/Contents/MacOS" ]; then
        echo "  ✓ MacOS directory exists"
    fi
    
    if [ -f "$BUNDLE_PATH/Contents/Info.plist" ]; then
        echo "  ✓ Info.plist exists"
    fi

    # Find the main executable
    MAIN_BINARY=""
    for candidate in "$BUNDLE_PATH/Contents/Resources/bin/gftp-gtk" \
                     "$BUNDLE_PATH/Contents/MacOS/gftp-gtk" \
                     "$BUNDLE_PATH/Contents/MacOS/gFTP"; do
        if [ -f "$candidate" ] && file "$candidate" 2>/dev/null | grep -q "Mach-O"; then
            MAIN_BINARY="$candidate"
            echo "  ✓ Found executable: $(basename $(dirname $candidate))/$(basename $candidate)"
            break
        fi
    done

    if [ -n "$MAIN_BINARY" ]; then
        echo "  Checking dylib dependencies..."
        BAD_DEPS=$(otool -L "$MAIN_BINARY" 2>/dev/null | grep -v "@" | grep -v "/usr/lib" | grep -v ":" | wc -l | tr -d ' ')
        if [ "$BAD_DEPS" -gt 0 ]; then
            echo -e "${YELLOW}  Warning: Found $BAD_DEPS non-relocatable dependencies${NC}"
            otool -L "$MAIN_BINARY" | grep -v "@" | grep -v "/usr/lib" | grep -v ":"
        else
            echo "  ✓ All dependencies are relocatable"
        fi
    fi

    echo ""
fi

# Summary
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}     Build Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Installed files:${NC}"
echo "  gFTP GTK: $GFTP_PREFIX/bin/gftp-gtk"
if [ -f "$DEST_FILE" ]; then
    echo "  gFTP Text: $DEST_FILE"
fi
echo ""

if [ "$CREATE_BUNDLE" = true ] && [ -d "$BUNDLE_PATH" ]; then
    echo -e "${BLUE}App bundle:${NC}"
    echo "  $BUNDLE_PATH"
    echo ""
    echo -e "${BLUE}To test the application:${NC}"
    echo "  open \"$BUNDLE_PATH\""
    echo ""
else
    echo -e "${BLUE}To run gFTP:${NC}"
    echo "  $GFTP_PREFIX/bin/gftp-gtk"
    echo ""
fi

echo -e "${BLUE}To build an app bundle manually:${NC}"
echo "  1. Install AppBundleGenerator from: https://github.com/yourusername/AppBundleGenerator"
echo "  2. Set APP_BUNDLE_GENERATOR environment variable"
echo "  3. Re-run this script"
echo ""

echo -e "${BLUE}Build information:${NC}"
echo "  GTK version: $(pkg-config --modversion gtk+-3.0)"
echo "  GLib version: $(pkg-config --modversion glib-2.0)"
echo "  Build directory: $GFTP_SOURCE/build"
echo "  Install prefix: $GFTP_PREFIX"
echo ""
