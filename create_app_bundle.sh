#!/bin/bash
# create_app_bundle.sh - Create macOS application bundle for gFTP
# This script creates a self-contained gFTP.app bundle with all dependencies

set -e

# Configuration
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/source/jhbuild/install}"
BUNDLE_NAME="gFTP.app"
BUNDLE_ID="org.gftp.gftp-gtk"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

# Verify install prefix exists
if [ ! -d "$INSTALL_PREFIX" ]; then
    error "Install prefix not found: $INSTALL_PREFIX"
fi

# Check for required binary
GFTP_GTK="$INSTALL_PREFIX/bin/gftp-gtk"
if [ ! -f "$GFTP_GTK" ]; then
    error "gftp-gtk not found at: $GFTP_GTK"
fi

info "Creating macOS application bundle: $BUNDLE_NAME"
info "Install prefix: $INSTALL_PREFIX"

# Remove existing bundle
if [ -d "$BUNDLE_NAME" ]; then
    warn "Removing existing bundle: $BUNDLE_NAME"
    rm -rf "$BUNDLE_NAME"
fi

# Create bundle structure
info "Creating bundle directory structure..."
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copy main executable
info "Copying gftp-gtk executable..."
cp "$GFTP_GTK" "$BUNDLE_NAME/Contents/MacOS/"
chmod +x "$BUNDLE_NAME/Contents/MacOS/gftp-gtk"

# Copy translations
if [ -d "$INSTALL_PREFIX/share/locale" ]; then
    info "Copying translations..."
    cp -R "$INSTALL_PREFIX/share/locale" "$BUNDLE_NAME/Contents/Resources/"
    LOCALE_COUNT=$(find "$BUNDLE_NAME/Contents/Resources/locale" -name "gftp.mo" | wc -l)
    info "Copied $LOCALE_COUNT translation files"
else
    warn "No translations found at $INSTALL_PREFIX/share/locale"
fi

# Copy icons if they exist
if [ -d "$INSTALL_PREFIX/share/pixmaps" ]; then
    info "Copying icons..."
    cp -R "$INSTALL_PREFIX/share/pixmaps" "$BUNDLE_NAME/Contents/Resources/"
fi

# Find and convert app icon to ICNS
info "Setting up application icon..."
ICON_ICNS=""
if [ -f "$SCRIPT_DIR/icons/scalable/gftp.svg" ]; then
    info "Found SVG icon, converting to ICNS..."
    TEMP_ICONSET=$(mktemp -d)/gftp.iconset
    mkdir -p "$TEMP_ICONSET"

    # Convert SVG to PNG at high resolution using qlmanage
    qlmanage -t -s 1024 -o /tmp "$SCRIPT_DIR/icons/scalable/gftp.svg" 2>/dev/null
    TEMP_PNG=$(ls /tmp/gftp.svg.png 2>/dev/null | head -1)

    if [ -f "$TEMP_PNG" ]; then
        # Generate all required icon sizes
        for size in 16 32 128 256 512; do
            sips -z $size $size "$TEMP_PNG" --out "$TEMP_ICONSET/icon_${size}x${size}.png" >/dev/null 2>&1
            sips -z $((size*2)) $((size*2)) "$TEMP_PNG" --out "$TEMP_ICONSET/icon_${size}x${size}@2x.png" >/dev/null 2>&1
        done

        # Create ICNS file
        iconutil -c icns "$TEMP_ICONSET" -o "$BUNDLE_NAME/Contents/Resources/gftp.icns"
        if [ -f "$BUNDLE_NAME/Contents/Resources/gftp.icns" ]; then
            ICON_ICNS="gftp.icns"
            info "Icon converted successfully"
        fi

        # Cleanup
        rm -rf "$(dirname "$TEMP_ICONSET")" "$TEMP_PNG"
    else
        warn "Failed to convert SVG icon"
    fi
elif [ -f "$SCRIPT_DIR/icons/48x48/gftp.png" ]; then
    warn "Using PNG icon (SVG not found, may not scale well)"
    cp "$SCRIPT_DIR/icons/48x48/gftp.png" "$BUNDLE_NAME/Contents/Resources/gftp.png"
    ICON_ICNS="gftp.png"
fi

# Get version from gftp-gtk
VERSION=$(strings "$GFTP_GTK" | grep -E '^2\.[0-9]+\.[0-9]+' | head -1 || echo "2.9.1b")

# Create Info.plist
info "Creating Info.plist..."
cat > "$BUNDLE_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>gftp-gtk</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>gFTP</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
EOF

# Add icon if we have one
if [ -n "$ICON_ICNS" ]; then
    cat >> "$BUNDLE_NAME/Contents/Info.plist" << EOF
    <key>CFBundleIconFile</key>
    <string>$ICON_ICNS</string>
EOF
fi

cat >> "$BUNDLE_NAME/Contents/Info.plist" << EOF
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>*</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>All Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPLGFTP" > "$BUNDLE_NAME/Contents/PkgInfo"

# Verify bundle structure
info "Verifying bundle structure..."
if [ ! -f "$BUNDLE_NAME/Contents/MacOS/gftp-gtk" ]; then
    error "Failed to create bundle: executable not found"
fi

if [ ! -f "$BUNDLE_NAME/Contents/Info.plist" ]; then
    error "Failed to create bundle: Info.plist not found"
fi

# Print bundle info
info "Bundle created successfully!"
echo ""
echo "Bundle information:"
echo "  Location: $SCRIPT_DIR/$BUNDLE_NAME"
echo "  Executable: $BUNDLE_NAME/Contents/MacOS/gftp-gtk"
echo "  Translations: $(find "$BUNDLE_NAME/Contents/Resources/locale" -name "gftp.mo" 2>/dev/null | wc -l | tr -d ' ') locales"
echo "  Version: $VERSION"
echo ""
echo "To test the bundle:"
echo "  open $BUNDLE_NAME"
echo ""
echo "To create a DMG:"
echo "  ./create_dmg.sh"
