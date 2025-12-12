# Building and Packaging gFTP for macOS

Complete guide for building gFTP natively on macOS and creating distributable application bundles.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Building gFTP with jhbuild](#building-gftp-with-jhbuild)
4. [Creating a macOS App Bundle](#creating-a-macos-app-bundle)
5. [Creating a DMG Installer](#creating-a-dmg-installer)
6. [Icon Management](#icon-management)
7. [Troubleshooting](#troubleshooting)

## Overview

This guide covers the complete process of building gFTP on macOS from source using jhbuild, then packaging it as a native macOS application bundle (.app) with proper icons and code signing.

### Build Strategy

- **jhbuild**: Builds GTK3 and all dependencies from source using only macOS native tools
- **No Homebrew dependencies**: Only uses Homebrew build tools (cmake, ninja, meson), not libraries
- **Native macOS**: Uses system clang and macOS SDK exclusively
- **AppBundleGenerator**: Creates proper .app bundles with icon conversion and code signing
- **DMG creation**: Packages the app for distribution

## Prerequisites

### Required Software

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Homebrew** (for build tools only)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Homebrew Build Tools**
   ```bash
   brew install cmake ninja meson pkg-config autoconf automake libtool gettext
   ```

### Verify Installation

```bash
# Check Xcode
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check clang
which clang
# Should output: /usr/bin/clang

# Check macOS SDK
ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
# Should show MacOSX.sdk
```

## Building gFTP with jhbuild

### Quick Start

If you already have jhbuild set up at `~/source/jhbuild/`, skip to step 3.

### Step 1: Set Up jhbuild (First Time Only)

Create directory structure and clone jhbuild:

```bash
mkdir -p ~/source/jhbuild
cd ~/source/jhbuild
git clone https://gitlab.gnome.org/GNOME/jhbuild.git jhbuild-src
```

Build and install jhbuild:

```bash
cd jhbuild-src
./autogen.sh --simple-install --prefix=$HOME/source/jhbuild/install
make
make install
```

Add to PATH:

```bash
export PATH=~/source/jhbuild/install/bin:$PATH
echo 'export PATH=~/source/jhbuild/install/bin:$PATH' >> ~/.zshrc
```

### Step 2: Set Up Modulesets

Download GTK-OSX modulesets:

```bash
cd ~/source/jhbuild
git clone https://gitlab.gnome.org/GNOME/gtk-osx.git gtk-osx-modulesets
```

Create local modulesets directory:

```bash
mkdir -p ~/source/jhbuild/modulesets
cp gtk-osx-modulesets/modulesets-stable/gtk-osx-bootstrap.modules modulesets/
cp gtk-osx-modulesets/modulesets-stable/gtk-osx.modules modulesets/
cp gtk-osx-modulesets/modulesets-stable/gtk-osx-network.modules modulesets/
```

Create `~/source/jhbuild/modulesets/gftp.modules`:

```xml
<?xml version="1.0"?>
<!DOCTYPE moduleset SYSTEM "moduleset.dtd">
<?xml-stylesheet type="text/xsl" href="moduleset.xsl"?>
<moduleset>
  <repository type="git" name="github"
      href="https://github.com/"/>

  <!-- gFTP - GTK+ FTP client -->
  <meson id="gftp" mesonargs="-Dgtk3=true -Dgtk2=false -Dssl=true">
    <branch repo="github" module="sedwards-ibowl/gftp.git"
            checkoutdir="gftp">
    </branch>
    <dependencies>
      <dep package="gtk+-3.0"/>
      <dep package="glib"/>
      <dep package="openssl"/>
      <dep package="intltool"/>
      <dep package="gettext"/>
    </dependencies>
  </meson>

</moduleset>
```

Create `~/source/jhbuild/jhbuildrc` (see JHBUILD.md for complete configuration).

### Step 3: Build gFTP

```bash
# Set up environment
export PATH=~/source/jhbuild/install/bin:$PATH

# Build bootstrap dependencies (~10-20 minutes)
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-bootstrap

# Build GTK3 and core libraries (~30-60 minutes)
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-gtk3

# Build gFTP (~2-5 minutes)
jhbuild -f ~/source/jhbuild/jhbuildrc build gftp
```

**Note:** See JHBUILD.md for detailed build instructions and troubleshooting.

### Step 4: Test gFTP

Run gFTP using jhbuild:

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc run ~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk
```

Or start a jhbuild shell:

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc shell
~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk
```

## Creating a macOS App Bundle

Once gFTP is built, you can create a proper macOS application bundle using AppBundleGenerator.

### Step 1: Build AppBundleGenerator

```bash
cd ~/source
git clone https://github.com/yourusername/AppBundleGenerator.git
cd AppBundleGenerator
make
```

This creates the `AppBundleGenerator` executable.

### Step 2: Create Install Script for gFTP

Create a helper script `~/source/jhbuild/checkout/gftp/install-gftp-app.sh`:

```bash
#!/bin/bash
# Creates a gFTP.app bundle for macOS

set -e

GFTP_BUILD_DIR="$HOME/source/jhbuild/checkout/gftp/build"
JHBUILD_INSTALL="$HOME/source/jhbuild/install"
APP_BUNDLE_GEN="$HOME/source/AppBundleGenerator/AppBundleGenerator"
DEST_DIR="${1:-$HOME/Desktop}"

echo "Creating gFTP.app bundle..."

# Create a wrapper script that sets up the environment
WRAPPER_SCRIPT="/tmp/gftp-launcher.sh"
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash
# gFTP launcher script

# Get the bundle's location
BUNDLE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JHBUILD_INSTALL="$HOME/source/jhbuild/install"

# Set up environment for GTK and libraries
export PATH="$JHBUILD_INSTALL/bin:$PATH"
export DYLD_LIBRARY_PATH="$JHBUILD_INSTALL/lib"
export XDG_DATA_DIRS="$JHBUILD_INSTALL/share:$XDG_DATA_DIRS"
export GDK_PIXBUF_MODULE_FILE="$JHBUILD_INSTALL/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export GTK_PATH="$JHBUILD_INSTALL"

# Launch gFTP
exec "$JHBUILD_INSTALL/bin/gftp-gtk" "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"

# Use AppBundleGenerator to create the bundle
"$APP_BUNDLE_GEN" \
  --icon "$HOME/source/jhbuild/checkout/gftp/icons/scalable/gftp.svg" \
  --sign - \
  --hardened-runtime \
  --allow-dyld-vars \
  --identifier com.gftp.gftp-gtk \
  --category public.app-category.utilities \
  --version "2.9.1" \
  --min-os 12.0 \
  'gFTP' "$DEST_DIR" "$WRAPPER_SCRIPT"

# Install the actual gFTP binary and libraries into jhbuild location
# (The wrapper script will find them there)
cd "$GFTP_BUILD_DIR"
ninja install

echo ""
echo "✓ gFTP.app created at: $DEST_DIR/gFTP.app"
echo ""
echo "Note: This app bundle requires jhbuild libraries at:"
echo "  $JHBUILD_INSTALL"
echo ""
echo "To create a standalone bundle, you would need to copy all"
echo "required libraries into the .app/Contents/Frameworks directory."
```

Make it executable:

```bash
chmod +x ~/source/jhbuild/checkout/gftp/install-gftp-app.sh
```

### Step 3: Create the App Bundle

```bash
cd ~/source/jhbuild/checkout/gftp
./install-gftp-app.sh
```

This creates `gFTP.app` on your Desktop.

### Step 4: Launch gFTP.app

```bash
open ~/Desktop/gFTP.app
```

### Alternative: Self-Contained Bundle (Advanced)

For a truly portable app that doesn't require jhbuild installation on the target system, you need to:

1. Copy all required libraries into the bundle
2. Use `install_name_tool` to rewrite library paths
3. Include GTK themes and data files

This is complex and requires a separate bundling tool. For development and personal use, the wrapper script approach above is sufficient.

## Creating a DMG Installer

Once you have `gFTP.app`, create a distributable DMG:

### Using the create_dmg_for_app.sh Script

```bash
cd ~/source/jhbuild/checkout/gftp

# If gFTP.app is on Desktop
./create_dmg_for_app.sh

# Or specify a custom path
./create_dmg_for_app.sh ~/Desktop/gFTP.app
```

This creates `gFTP.dmg` containing:
- The gFTP.app bundle
- Source code (optional)

### Manual DMG Creation

```bash
# Create a temporary directory
mkdir -p /tmp/gftp-dmg
cp -R ~/Desktop/gFTP.app /tmp/gftp-dmg/

# Create DMG
hdiutil create -volname "gFTP Installer" \
  -srcfolder /tmp/gftp-dmg \
  -ov -format UDZO \
  ~/Desktop/gFTP.dmg

# Clean up
rm -rf /tmp/gftp-dmg
```

### Distribution Notes

For public distribution, you should:

1. **Code sign with Developer ID:**
   ```bash
   codesign -s "Developer ID Application: Your Name" \
     --deep --force --options runtime \
     ~/Desktop/gFTP.app
   ```

2. **Notarize the app:**
   ```bash
   xcrun notarytool submit gFTP.dmg \
     --keychain-profile "AC_PASSWORD" \
     --wait
   ```

3. **Staple the notarization ticket:**
   ```bash
   xcrun stapler staple gFTP.app
   ```

## Icon Management

### Current Icon Situation

gFTP includes icons in multiple formats:

**For GTK UI (file type icons):**
- `docs/sample.gftp/*.xpm` - XPM format (X11 legacy format)
- Used for file list icons (directories, executables, documents, etc.)
- These are fine for GTK+ usage and will work on macOS

**For Application Icon:**
- `icons/scalable/gftp.svg` - **Scalable SVG** (recommended for app bundle)
- `icons/16x16/gftp.png` through `icons/48x48/gftp.png` - PNG icons for various sizes

### App Bundle Icon Conversion

AppBundleGenerator automatically handles icon conversion:

```bash
# Input: SVG (recommended - scales to all sizes)
--icon icons/scalable/gftp.svg

# Input: PNG (must be at least 512x512 for best results)
--icon icons/48x48/gftp.png  # Will work but may be blurry at large sizes

# Input: ICNS (pre-converted)
--icon gftp.icns
```

**What AppBundleGenerator creates:**
- Converts SVG/PNG to .icns format
- Generates all required icon sizes:
  - 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
  - Each with 1x and 2x (Retina) variants
- Places `icon.icns` in `gFTP.app/Contents/Resources/`

### Creating Custom ICNS Manually

If you want to create a custom icon:

1. **From SVG:**
   ```bash
   # Use AppBundleGenerator (easiest)
   AppBundleGenerator --icon custom.svg ...

   # Or manually with qlmanage and sips
   qlmanage -t -s 1024 -o /tmp custom.svg
   # Then use sips to create iconset
   ```

2. **From PNG:**
   ```bash
   mkdir MyIcon.iconset
   sips -z 16 16     icon.png --out MyIcon.iconset/icon_16x16.png
   sips -z 32 32     icon.png --out MyIcon.iconset/icon_16x16@2x.png
   sips -z 32 32     icon.png --out MyIcon.iconset/icon_32x32.png
   sips -z 64 64     icon.png --out MyIcon.iconset/icon_32x32@2x.png
   sips -z 128 128   icon.png --out MyIcon.iconset/icon_128x128.png
   sips -z 256 256   icon.png --out MyIcon.iconset/icon_128x128@2x.png
   sips -z 256 256   icon.png --out MyIcon.iconset/icon_256x256.png
   sips -z 512 512   icon.png --out MyIcon.iconset/icon_256x256@2x.png
   sips -z 512 512   icon.png --out MyIcon.iconset/icon_512x512.png
   sips -z 1024 1024 icon.png --out MyIcon.iconset/icon_512x512@2x.png
   iconutil -c icns MyIcon.iconset
   ```

### XPM Icons for File Types

The XPM icons in `docs/sample.gftp/` are used by gFTP's GTK UI to display different file types in the file browser:
- `dir.xpm` - Directories
- `exe.xpm` - Executables
- `doc.xpm` - Documents
- `img.xpm` - Images
- etc.

**These do NOT need conversion** because:
1. GTK+ on macOS handles XPM format natively via GdkPixbuf
2. They're not used for the app bundle icon
3. They're small UI decorations (typically 16x16 or 24x24)

If you want to modernize them:
- Convert to PNG for slightly better quality and smaller file size
- Update gFTP code to load PNG instead of XPM
- Use higher resolution for Retina displays (32x32 or 48x48)

## Troubleshooting

### Build Issues

**"configure: error: Package requirements were not met"**
- Dependency not found by pkg-config
- Check that jhbuild built all dependencies successfully
- Verify `PKG_CONFIG_PATH` in jhbuildrc

**"Library not loaded" when running gFTP**
- Set `DYLD_LIBRARY_PATH`:
  ```bash
  export DYLD_LIBRARY_PATH=~/source/jhbuild/install/lib
  ```
- Or use `jhbuild run` to set environment automatically

**"command not found: jhbuild"**
- Add to PATH:
  ```bash
  export PATH=~/source/jhbuild/install/bin:$PATH
  ```

### App Bundle Issues

**"App is damaged and can't be opened"**
- Bundle needs to be code signed (even ad-hoc)
- Use `--sign -` with AppBundleGenerator
- Or: Right-click → Open to bypass Gatekeeper

**Icon doesn't appear in app bundle**
- Verify SVG is valid: `qlmanage -t -s 512 icon.svg`
- Check that icon.icns exists in `gFTP.app/Contents/Resources/`
- Try using PNG instead of SVG

**App launches but shows errors about missing libraries**
- Wrapper script may not be setting `DYLD_LIBRARY_PATH` correctly
- Check that jhbuild libraries are at `~/source/jhbuild/install/lib`
- Run from Terminal to see error messages

### jhbuild Issues

**Build fails for specific module**
```bash
# Clean and rebuild
jhbuild -f ~/source/jhbuild/jhbuildrc cleanone <module-name>
jhbuild -f ~/source/jhbuild/jhbuildrc buildone <module-name>
```

**OpenSSL build fails**
- Check `module_autogenargs` in jhbuildrc
- Ensure it has `'openssl': 'shared'`

**Cairo build fails with X11 errors**
- Check `module_mesonargs` for cairo
- Ensure X11 is disabled: `-Dxcb=disabled -Dxlib=disabled`

## Quick Reference

### Essential Commands

```bash
# Build gFTP
jhbuild -f ~/source/jhbuild/jhbuildrc build gftp

# Rebuild gFTP after code changes
jhbuild -f ~/source/jhbuild/jhbuildrc buildone gftp

# Run gFTP
jhbuild -f ~/source/jhbuild/jhbuildrc run ~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk

# Create app bundle
~/source/jhbuild/checkout/gftp/install-gftp-app.sh

# Create DMG
~/source/jhbuild/checkout/gftp/create_dmg_for_app.sh
```

### Directory Structure

```
~/source/
├── jhbuild/                    # jhbuild installation
│   ├── jhbuildrc              # Configuration
│   ├── install/               # All built libraries
│   │   ├── bin/               # Executables (including gftp-gtk after install)
│   │   ├── lib/               # Shared libraries (.dylib)
│   │   └── share/             # Data files
│   ├── checkout/              # Source code
│   │   └── gftp/              # gFTP source (this repository)
│   │       ├── build/         # Meson build directory
│   │       ├── icons/         # Application icons
│   │       └── docs/          # Documentation
│   └── modulesets/            # Build definitions
│
└── AppBundleGenerator/        # App bundle creation tool
    └── AppBundleGenerator     # Executable
```

## Additional Resources

- **JHBUILD.md** - Complete jhbuild setup and usage guide
- **CLAUDE.md** - gFTP codebase documentation
- **AppBundleGenerator/README.md** - App bundle creation documentation
- **create_dmg_for_app.sh** - DMG creation script
- [jhbuild Manual](https://developer.gnome.org/jhbuild/stable/)
- [GTK-OSX Project](https://gitlab.gnome.org/GNOME/gtk-osx)
- [macOS Bundle Programming Guide](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/)

## Summary

1. **Build with jhbuild** - Creates gFTP and all dependencies natively
2. **Test** - Run with `jhbuild run` to verify it works
3. **Create .app bundle** - Use AppBundleGenerator with SVG icon
4. **Create DMG** - Package for distribution
5. **(Optional) Code sign and notarize** - For public distribution

This workflow gives you a working gFTP on macOS that integrates properly with the operating system.
