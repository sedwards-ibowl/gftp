#!/bin/bash
#
# create_app_bundle.sh - Package gftp into a macOS application bundle
#
# This script creates a gFTP.app bundle with relocatable translations
# that will be automatically detected by the app at runtime.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/source/jhbuild/install}"
BUNDLE_NAME="gFTP.app"
BUNDLE_DIR="${SCRIPT_DIR}/${BUNDLE_NAME}"

echo "Creating gFTP.app bundle..."

# Clean previous bundle if it exists
if [ -d "$BUNDLE_DIR" ]; then
    echo "Removing existing bundle..."
    rm -rf "$BUNDLE_DIR"
fi

# Create bundle structure
echo "Creating bundle structure..."
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"
mkdir -p "${BUNDLE_DIR}/Contents/Resources/locale"

# Copy the binary
echo "Copying gftp-gtk binary..."
cp "${INSTALL_PREFIX}/bin/gftp-gtk" "${BUNDLE_DIR}/Contents/MacOS/"

# Copy all translation files
echo "Copying translation files..."
if [ -d "${INSTALL_PREFIX}/share/locale" ]; then
    # Copy all locale directories that contain gftp.mo files
    for locale_dir in "${INSTALL_PREFIX}/share/locale"/*; do
        if [ -d "$locale_dir" ]; then
            locale=$(basename "$locale_dir")
            if [ -f "$locale_dir/LC_MESSAGES/gftp.mo" ]; then
                echo "  - Copying locale: $locale"
                mkdir -p "${BUNDLE_DIR}/Contents/Resources/locale/${locale}/LC_MESSAGES"
                cp "$locale_dir/LC_MESSAGES/gftp.mo" \
                   "${BUNDLE_DIR}/Contents/Resources/locale/${locale}/LC_MESSAGES/"
            fi
        fi
    done
else
    echo "Warning: No translations found at ${INSTALL_PREFIX}/share/locale"
fi

# Create Info.plist
echo "Creating Info.plist..."
cat > "${BUNDLE_DIR}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>gftp-gtk</string>
    <key>CFBundleIdentifier</key>
    <string>org.gftp.gftp-gtk</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>gFTP</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.9.1b</string>
    <key>CFBundleVersion</key>
    <string>2.9.1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Copy icon if it exists
if [ -f "${INSTALL_PREFIX}/share/pixmaps/gftp.png" ]; then
    echo "Copying icon..."
    cp "${INSTALL_PREFIX}/share/pixmaps/gftp.png" "${BUNDLE_DIR}/Contents/Resources/"
fi

# Count translations
locale_count=$(find "${BUNDLE_DIR}/Contents/Resources/locale" -name "gftp.mo" 2>/dev/null | wc -l)

echo ""
echo "✓ Bundle created successfully!"
echo "  Location: ${BUNDLE_DIR}"
echo "  Translations: ${locale_count} locales"
echo ""
echo "To test the bundle:"
echo "  open ${BUNDLE_DIR}"
echo ""
echo "Or run directly:"
echo "  ${BUNDLE_DIR}/Contents/MacOS/gftp-gtk"
echo ""
echo "To verify translations are found:"
echo "  LANG=es_ES.UTF-8 ${BUNDLE_DIR}/Contents/MacOS/gftp-gtk"
echo ""
