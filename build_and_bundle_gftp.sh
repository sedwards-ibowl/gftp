#!/bin/bash
set -e

# Configuration
INSTALL_PREFIX="$(pwd)/build/install"
BUILD_DIR="build"
BUNDLE_NAME="gFTP.app"

# Function to clean up build artifacts
clean() {
    echo "Cleaning up build artifacts..."
    rm -rf "$BUILD_DIR"
    rm -rf "$BUNDLE_NAME"
    echo "Clean up complete."
    exit 0
}

# Check for 'clean' argument
if [ "$1" == "clean" ]; then
    clean
fi

# 1. Configure Meson with a local install prefix
meson setup "$BUILD_DIR" --wipe -Dgtk3=true -Dgtk2=false --prefix="$INSTALL_PREFIX"

# 2. Build the project
ninja -C "$BUILD_DIR"

# 3. Install the project to the local prefix
ninja -C "$BUILD_DIR" install

# 4. Create the basic bundle structure
rm -rf "$BUNDLE_NAME"
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources/lib"

# 5. Copy the executable
cp "$INSTALL_PREFIX/bin/gftp-gtk" "$BUNDLE_NAME/Contents/MacOS/"

# 6. Copy the resources
cp -R "$INSTALL_PREFIX/share/" "$BUNDLE_NAME/Contents/Resources/"

# 7. List dependencies
echo "Dependencies for gftp-gtk:"
otool -L "$BUNDLE_NAME/Contents/MacOS/gftp-gtk"

echo "Library dependency analysis complete. Next steps: copy libraries, create Info.plist, and fix rpaths."
