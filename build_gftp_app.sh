#!/bin/bash
#
# build_gftp_app.sh - Build gFTP and create macOS app bundle
#
# This script:
# 1. Builds gFTP with meson
# 2. Installs to jhbuild prefix
# 3. Creates relocatable app bundle with all dependencies
#
# Requirements:
# - jhbuild with GTK3 stack installed
# - AppBundleGenerator tool
# - meson, ninja
#

set -e  # Exit on error

# Configuration
JHBUILD_PREFIX="${JHBUILD_PREFIX:-$HOME/source/jhbuild/install}"
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
echo -e "${GREEN}  gFTP macOS App Bundle Builder${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  jhbuild prefix: $JHBUILD_PREFIX"
echo "  Source directory: $GFTP_SOURCE"
echo "  AppBundleGenerator: $APP_BUNDLE_GENERATOR"
echo "  Destination: $DEST_DIR"
echo "  Bundle identifier: $BUNDLE_ID"
echo "  Version: $VERSION"
echo ""

# Verify prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if [ ! -f "$APP_BUNDLE_GENERATOR" ]; then
    echo -e "${RED}Error: AppBundleGenerator not found at: $APP_BUNDLE_GENERATOR${NC}"
    echo "Please build AppBundleGenerator first:"
    echo "  cd ~/source/AppBundleGenerator && make"
    exit 1
fi

if [ ! -d "$JHBUILD_PREFIX" ]; then
    echo -e "${RED}Error: jhbuild prefix not found at: $JHBUILD_PREFIX${NC}"
    echo "Please build GTK3 stack with jhbuild first"
    exit 1
fi

if ! command -v meson &> /dev/null; then
    echo -e "${RED}Error: meson not found in PATH${NC}"
    exit 1
fi

if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Error: ninja not found in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites found${NC}"
echo ""

# Step 1: Ensure gFTP is built and installed
echo -e "${YELLOW}Step 1: Ensuring gFTP is installed...${NC}"

cd "$GFTP_SOURCE"

# Set up jhbuild environment
export PATH="$JHBUILD_PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$JHBUILD_PREFIX/lib/pkgconfig:$JHBUILD_PREFIX/share/pkgconfig"
export LD_LIBRARY_PATH="$JHBUILD_PREFIX/lib:$LD_LIBRARY_PATH"

# Check if gftp-gtk binary exists and is recent
if [ -f "$JHBUILD_PREFIX/bin/gftp-gtk" ]; then
    BINARY_AGE=$(find "$JHBUILD_PREFIX/bin/gftp-gtk" -mmin +60 2>/dev/null | wc -l)
    if [ "$BINARY_AGE" -eq 0 ]; then
        echo "  gFTP binary is recent (< 1 hour old), skipping rebuild"
    else
        echo "  gFTP binary is old, rebuilding via jhbuild..."
        cd ~/source/jhbuild
        ./install/bin/jhbuild -f jhbuildrc buildone gftp
        cd "$GFTP_SOURCE"
    fi
else
    echo "  gFTP not found, building via jhbuild..."
    cd ~/source/jhbuild
    ./install/bin/jhbuild -f jhbuildrc buildone gftp
    cd "$GFTP_SOURCE"
fi

echo -e "${GREEN}✓ gFTP built and installed${NC}"
echo ""

# Step 2: Find icon
echo -e "${YELLOW}Step 2: Locating app icon...${NC}"

ICON_PATH=""
# Prefer PNG icon (correct file cabinet + globe design)
for icon in "$GFTP_SOURCE/icons/48x48/gftp.png" \
            "$JHBUILD_PREFIX/share/icons/hicolor/48x48/apps/gftp.png" \
            "$GFTP_SOURCE/icons/scalable/gftp.svg" \
            "$JHBUILD_PREFIX/share/icons/hicolor/scalable/apps/gftp.svg"; do
    if [ -f "$icon" ]; then
        ICON_PATH="$icon"
        echo "  Found icon: $ICON_PATH"
        break
    fi
done

if [ -z "$ICON_PATH" ]; then
    echo -e "${YELLOW}  Warning: No icon found, continuing without icon${NC}"
fi

echo ""

# Step 3: Create app bundle with AppBundleGenerator
echo -e "${YELLOW}Step 3: Creating macOS app bundle...${NC}"

BUNDLE_ARGS=()
BUNDLE_ARGS+=("--identifier" "$BUNDLE_ID")
BUNDLE_ARGS+=("--version" "$VERSION")
BUNDLE_ARGS+=("--category" "public.app-category.utilities")
BUNDLE_ARGS+=("--min-os" "12.0")
BUNDLE_ARGS+=("--sign" "-")
BUNDLE_ARGS+=("--hardened-runtime")
BUNDLE_ARGS+=("--allow-dyld-vars")
BUNDLE_ARGS+=("--stage-dependencies" "$JHBUILD_PREFIX")

if [ -n "$ICON_PATH" ]; then
    BUNDLE_ARGS+=("--icon" "$ICON_PATH")
fi

echo "  Running AppBundleGenerator..."
echo "  Command: $APP_BUNDLE_GENERATOR ${BUNDLE_ARGS[*]} \"$APP_NAME\" \"$DEST_DIR\" \"$JHBUILD_PREFIX/bin/gftp-gtk\""
echo ""

"$APP_BUNDLE_GENERATOR" \
    "${BUNDLE_ARGS[@]}" \
    "$APP_NAME" \
    "$DEST_DIR" \
    "$JHBUILD_PREFIX/bin/gftp-gtk"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: AppBundleGenerator failed${NC}"
    exit 1
fi

BUNDLE_PATH="$DEST_DIR/$APP_NAME.app"

echo ""
echo -e "${GREEN}✓ App bundle created successfully${NC}"
echo ""

# Step 4: Verify the bundle
echo -e "${YELLOW}Step 4: Verifying app bundle...${NC}"

if [ ! -d "$BUNDLE_PATH" ]; then
    echo -e "${RED}Error: Bundle not created at $BUNDLE_PATH${NC}"
    exit 1
fi

echo "  Checking bundle structure..."
for path in "Contents/Info.plist" \
            "Contents/MacOS/gftp-gtk" \
            "Contents/Resources/lib" \
            "Contents/Resources/share"; do
    if [ ! -e "$BUNDLE_PATH/$path" ]; then
        echo -e "${RED}  ✗ Missing: $path${NC}"
        exit 1
    fi
done

echo "  Checking dylib dependencies..."
MAIN_BINARY="$BUNDLE_PATH/Contents/MacOS/gftp-gtk"
if file "$MAIN_BINARY" | grep -q "shell script"; then
    echo "  Binary is a launcher script (expected for staged dependencies)"
    # Find the actual binary
    ACTUAL_BINARY=$(grep -o '[^"]*-bin' "$MAIN_BINARY" 2>/dev/null | head -1)
    if [ -n "$ACTUAL_BINARY" ]; then
        MAIN_BINARY="$BUNDLE_PATH/Contents/MacOS/$(basename "$ACTUAL_BINARY")"
    fi
fi

if [ -f "$MAIN_BINARY" ]; then
    BAD_DEPS=$(otool -L "$MAIN_BINARY" 2>/dev/null | grep -v "@" | grep -v "/usr/lib" | grep -v ":" | wc -l | tr -d ' ')
    if [ "$BAD_DEPS" -gt 0 ]; then
        echo -e "${YELLOW}  Warning: Found $BAD_DEPS non-relocatable dependencies${NC}"
        otool -L "$MAIN_BINARY" | grep -v "@" | grep -v "/usr/lib" | grep -v ":"
    else
        echo "  ✓ All dependencies are relocatable"
    fi
fi

echo "  Checking GSettings schemas..."
if [ -f "$BUNDLE_PATH/Contents/Resources/share/glib-2.0/schemas/gschemas.compiled" ]; then
    echo "  ✓ GSettings schemas compiled"
else
    echo -e "${YELLOW}  Warning: GSettings schemas not found${NC}"
fi

echo "  Checking translations..."
LOCALE_COUNT=$(find "$BUNDLE_PATH/Contents/Resources/share/locale" -name "gftp.mo" 2>/dev/null | wc -l | tr -d ' ')
if [ "$LOCALE_COUNT" -gt 0 ]; then
    echo "  ✓ Found $LOCALE_COUNT translation files"
else
    echo -e "${YELLOW}  Warning: No translation files found${NC}"
fi

echo "  Checking code signature..."
if codesign -dv "$BUNDLE_PATH" 2>&1 | grep -q "Signature="; then
    echo "  ✓ Bundle is code signed"
else
    echo -e "${YELLOW}  Warning: Bundle is not code signed${NC}"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}     Build Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}App bundle location:${NC}"
echo "  $BUNDLE_PATH"
echo ""
echo -e "${BLUE}To test the application:${NC}"
echo "  open \"$BUNDLE_PATH\""
echo ""
echo -e "${BLUE}To create a DMG:${NC}"
echo "  cd $GFTP_SOURCE"
echo "  ./create_dmg_for_app.sh \"$BUNDLE_PATH\""
echo ""
