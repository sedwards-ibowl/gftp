# Building gFTP with jhbuild on macOS

This guide provides complete instructions for building gFTP from source on macOS using jhbuild. This setup uses only macOS native tools (Xcode Command Line Tools) and builds all dependencies from source, with no Homebrew library dependencies.

## Overview

jhbuild is a tool designed to build collections of software packages from source. This setup:
- Uses macOS native clang compiler and SDK
- Builds GTK3 and all dependencies from source
- Installs everything to `~/source/jhbuild/install/`
- Does NOT link against Homebrew libraries (only uses Homebrew build tools like cmake, ninja, meson)

## Prerequisites

### Required Software

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Homebrew** (for build tools only, not libraries)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Homebrew Build Tools**
   ```bash
   brew install cmake ninja meson pkg-config autoconf automake libtool gettext
   ```

### Verify Prerequisites

```bash
# Check Xcode Command Line Tools
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer (or /Library/Developer/CommandLineTools)

# Check clang
which clang
# Should output: /usr/bin/clang

# Check macOS SDK exists
ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
# Should show MacOSX.sdk or similar
```

## Installation Steps

### 1. Set Up Directory Structure

Create the jhbuild directory structure:

```bash
mkdir -p ~/source/jhbuild
cd ~/source/jhbuild
```

### 2. Clone jhbuild Source

```bash
git clone https://gitlab.gnome.org/GNOME/jhbuild.git jhbuild-src
cd jhbuild-src
```

### 3. Build and Install jhbuild

```bash
./autogen.sh --simple-install --prefix=$HOME/source/jhbuild/install
make
make install
```

This installs jhbuild to `~/source/jhbuild/install/bin/jhbuild`.

### 4. Set Up Environment

Add jhbuild to your PATH:

```bash
export PATH=~/source/jhbuild/install/bin:$PATH
```

Consider adding this to your `~/.zshrc` or `~/.bash_profile`:

```bash
echo 'export PATH=~/source/jhbuild/install/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

### 5. Download Modulesets

jhbuild uses "modulesets" (XML files) that define what to build and how. Download the GTK-OSX modulesets:

```bash
cd ~/source/jhbuild
git clone https://gitlab.gnome.org/GNOME/gtk-osx.git gtk-osx-modulesets
```

Create a local modulesets directory and copy the needed files:

```bash
mkdir -p ~/source/jhbuild/modulesets
cp gtk-osx-modulesets/modulesets-stable/gtk-osx-bootstrap.modules modulesets/
cp gtk-osx-modulesets/modulesets-stable/gtk-osx.modules modulesets/
cp gtk-osx-modulesets/modulesets-stable/gtk-osx-network.modules modulesets/
```

### 6. Create gftp Moduleset

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

### 7. Create jhbuildrc Configuration

Create `~/source/jhbuild/jhbuildrc`:

```python
# JHBuild configuration for macOS native GTK3 build
# No Homebrew dependencies - macOS SDK and native tools only

import os

# Prefix where GTK3 and dependencies will be installed
prefix = os.path.expanduser('~/source/jhbuild/install')
checkoutroot = os.path.expanduser('~/source/jhbuild/checkout')
buildroot = os.path.expanduser('~/source/jhbuild/build')

# Use macOS native tools
os.environ['CC'] = '/usr/bin/clang'
os.environ['CXX'] = '/usr/bin/clang++'
os.environ['OBJC'] = '/usr/bin/clang'

# Compiler and linker flags for macOS
_macos_sdk = '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'
os.environ['CFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'
os.environ['CXXFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'
os.environ['LDFLAGS'] = f'-isysroot {_macos_sdk} -L{prefix}/lib'
os.environ['OBJCFLAGS'] = f'-isysroot {_macos_sdk} -I{prefix}/include'

# PKG_CONFIG settings - use LIBDIR to completely override default search paths
# This prevents pkg-config from finding Homebrew libraries
os.environ['PKG_CONFIG_LIBDIR'] = f'{prefix}/lib/pkgconfig:{prefix}/share/pkgconfig'
os.environ['PKG_CONFIG_PATH'] = f'{prefix}/lib/pkgconfig:{prefix}/share/pkgconfig'
os.environ['PKG_CONFIG'] = '/opt/homebrew/bin/pkg-config'

# Path settings - include Homebrew build tools but exclude Homebrew libraries
# Homebrew bin is at END of PATH (lowest priority) for build tools only (cmake, ninja, automake)
# Homebrew libraries are NOT in LDFLAGS, so they won't be linked
os.environ['PATH'] = f'{prefix}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Applications/Xcode.app/Contents/Developer/usr/bin:/opt/homebrew/bin'

# Exclude Homebrew library paths - we only use Homebrew build tools, not libraries
if 'HOMEBREW_PREFIX' in os.environ:
    del os.environ['HOMEBREW_PREFIX']

# Module sets for GTK3 and gftp
modulesets_dir = os.path.expanduser('~/source/jhbuild/modulesets')
moduleset = [
    'gtk-osx-bootstrap.modules',
    'gtk-osx.modules',
    'gtk-osx-network.modules',
    'gftp.modules'
]
modules = ['meta-gtk-osx-bootstrap', 'meta-gtk-osx-gtk3', 'gftp']

# Build configuration
makeargs = '-j4'  # Parallel build with 4 jobs (adjust for your CPU)
nice_build = True

# Disable default autogenargs that break openssl and other non-autotools projects
autogenargs = ''

# Module-specific autogenargs overrides
module_autogenargs = {
    'openssl': 'shared',  # Only pass 'shared' to openssl Configure
}

# Module-specific mesonargs for native macOS builds (no X11)
module_mesonargs = {
    'cairo': '-Dfontconfig=enabled -Dfreetype=enabled -Dxcb=disabled -Dxlib=disabled -Dxlib-xcb=disabled -Dquartz=enabled -Dzlib=enabled -Dtests=disabled',
}

# Skip modules that require X11 or Linux-specific features
skip = ['gtk-doc']

# Installation settings
use_local_modulesets = True
modulesets_dir = os.path.expanduser('~/source/jhbuild/modulesets')

# Interaction settings
interact = True
nonetwork = False

# Tarball location
tarballdir = os.path.expanduser('~/source/jhbuild/pkgs')
```

**Important:** Adjust the SDK path and Homebrew path if needed:
- For Intel Macs, change `/opt/homebrew/bin` to `/usr/local/bin`
- Verify SDK path matches your Xcode installation

## Building the Software

### Quick Start - Automated Build

Create a build script `~/source/jhbuild/build-gftp.sh`:

```bash
#!/bin/bash
set -e

export PATH=~/source/jhbuild/install/bin:$PATH

echo "=== Building Bootstrap Dependencies ==="
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-bootstrap

echo ""
echo "=== Building GTK3 and Core Libraries ==="
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-gtk3

echo ""
echo "=== Building gFTP ==="
jhbuild -f ~/source/jhbuild/jhbuildrc build gftp

echo ""
echo "✓ Build complete!"
echo ""
echo "To run gFTP:"
echo "  jhbuild -f ~/source/jhbuild/jhbuildrc run ~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk"
```

Make it executable and run:

```bash
chmod +x ~/source/jhbuild/build-gftp.sh
~/source/jhbuild/build-gftp.sh
```

### Manual Step-by-Step Build

If you prefer to build step-by-step or if the automated build fails:

#### Step 1: Build Bootstrap Dependencies

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-bootstrap
```

This builds basic dependencies like zlib, libpng, libjpeg, libtiff, etc.

**Expected time:** ~10-20 minutes

#### Step 2: Build GTK3 and Core Libraries

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc build meta-gtk-osx-gtk3
```

This builds GTK3 and all its dependencies (glib, cairo, pango, gdk-pixbuf, etc.).

**Expected time:** ~30-60 minutes

#### Step 3: Build gFTP

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc build gftp
```

This builds gFTP itself, which will be checked out to `~/source/jhbuild/checkout/gftp/`.

**Expected time:** ~2-5 minutes

## Running gFTP

### Using jhbuild run

The easiest way to run gFTP is using `jhbuild run`, which sets up the environment automatically:

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc run ~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk
```

### Using jhbuild shell

You can also start a shell with the jhbuild environment:

```bash
jhbuild -f ~/source/jhbuild/jhbuildrc shell
```

Then run gFTP directly:

```bash
~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk
```

### Setting Environment Manually

If you want to run gFTP outside of jhbuild:

```bash
export PATH=~/source/jhbuild/install/bin:$PATH
export PKG_CONFIG_PATH=~/source/jhbuild/install/lib/pkgconfig
export DYLD_LIBRARY_PATH=~/source/jhbuild/install/lib
export XDG_DATA_DIRS=~/source/jhbuild/install/share

~/source/jhbuild/checkout/gftp/build/src/gtk/gftp-gtk
```

## Developing gFTP

### Rebuilding gFTP After Code Changes

When you make changes to the gFTP source code:

```bash
# Rebuild gFTP only (not dependencies)
jhbuild -f ~/source/jhbuild/jhbuildrc buildone gftp
```

### Cleaning and Rebuilding

If you need a clean rebuild:

```bash
# Clean gFTP build artifacts
jhbuild -f ~/source/jhbuild/jhbuildrc cleanone gftp

# Rebuild from scratch
jhbuild -f ~/source/jhbuild/jhbuildrc buildone gftp
```

### Building Manually with Meson

You can also build gFTP manually from the checkout directory:

```bash
cd ~/source/jhbuild/checkout/gftp

# Clean previous build
rm -rf build

# Configure with meson (in jhbuild environment)
jhbuild -f ~/source/jhbuild/jhbuildrc run meson setup build -Dgtk3=true -Dgtk2=false -Dssl=true

# Build
jhbuild -f ~/source/jhbuild/jhbuildrc run ninja -C build

# Run
jhbuild -f ~/source/jhbuild/jhbuildrc run ./build/src/gtk/gftp-gtk
```

## Useful jhbuild Commands

### Query Information

```bash
# List all modules that would be built for a target
jhbuild -f ~/source/jhbuild/jhbuildrc list gftp

# Show information about a specific module
jhbuild -f ~/source/jhbuild/jhbuildrc info gtk+-3.0

# Show what depends on a module
jhbuild -f ~/source/jhbuild/jhbuildrc rdepends glib

# Check system dependencies
jhbuild -f ~/source/jhbuild/jhbuildrc sysdeps gftp
```

### Build Operations

```bash
# Build a module and all its dependencies
jhbuild -f ~/source/jhbuild/jhbuildrc build <module-name>

# Build only a single module (skip dependencies)
jhbuild -f ~/source/jhbuild/jhbuildrc buildone <module-name>

# Update source code without building
jhbuild -f ~/source/jhbuild/jhbuildrc update <module-name>

# Clean build artifacts
jhbuild -f ~/source/jhbuild/jhbuildrc cleanone <module-name>

# Uninstall a module
jhbuild -f ~/source/jhbuild/jhbuildrc uninstall <module-name>
```

## Troubleshooting

### Build Failures

If a build fails:

1. **Read the error message carefully** - it usually indicates what's wrong
2. **Check for missing dependencies**:
   ```bash
   jhbuild -f ~/source/jhbuild/jhbuildrc sysdeps <failed-module>
   ```
3. **Try cleaning and rebuilding**:
   ```bash
   jhbuild -f ~/source/jhbuild/jhbuildrc cleanone <failed-module>
   jhbuild -f ~/source/jhbuild/jhbuildrc buildone <failed-module>
   ```
4. **Check the build log** - jhbuild shows where logs are saved
5. **Verify your jhbuildrc** - ensure paths are correct

### Common Issues

#### "configure: error: Package requirements were not met"

This means pkg-config can't find a dependency. Check that:
- The dependency was built successfully
- `PKG_CONFIG_PATH` is set correctly in jhbuildrc
- The `.pc` file exists in `~/source/jhbuild/install/lib/pkgconfig/`

#### "clang: error: SDK does not contain 'libc++'"

Your macOS SDK path may be incorrect. Update `_macos_sdk` in jhbuildrc:

```bash
# List available SDKs
ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
```

#### "command not found: meson" or "command not found: ninja"

Build tools aren't in PATH. Install them via Homebrew:

```bash
brew install meson ninja cmake
```

#### gFTP builds but won't run - "Library not loaded"

The runtime environment isn't set. Use `jhbuild run` or set `DYLD_LIBRARY_PATH`:

```bash
export DYLD_LIBRARY_PATH=~/source/jhbuild/install/lib
```

#### OpenSSL build fails

OpenSSL has special build requirements. Ensure `module_autogenargs` for openssl is set in jhbuildrc (see configuration above).

### Getting Help

If you encounter issues:

1. Check jhbuild documentation: https://gitlab.gnome.org/GNOME/jhbuild
2. Check GTK-OSX documentation: https://gitlab.gnome.org/GNOME/gtk-osx
3. Review build logs in the terminal output
4. Check `~/source/jhbuild/build/` for detailed build logs

## Directory Reference

After a complete build, your directory structure will look like:

```
~/source/jhbuild/
├── jhbuildrc                   # Configuration file
├── jhbuild-src/                # jhbuild source code
├── gtk-osx-modulesets/         # GTK-OSX moduleset repository
├── modulesets/                 # Local modulesets
│   ├── gtk-osx-bootstrap.modules
│   ├── gtk-osx.modules
│   ├── gtk-osx-network.modules
│   └── gftp.modules
├── install/                    # Installation prefix
│   ├── bin/                    # Executables (jhbuild, gtk3-demo, etc.)
│   ├── lib/                    # Libraries (.dylib files)
│   │   └── pkgconfig/          # pkg-config files (.pc)
│   ├── include/                # Header files
│   └── share/                  # Data files, translations, etc.
├── checkout/                   # Source code checkouts
│   ├── gftp/                   # gFTP source code
│   │   ├── build/              # Meson build directory
│   │   └── ...
│   ├── gtk+-3.0/
│   ├── glib/
│   └── ...                     # Other dependencies
├── build/                      # Build artifacts (for autotools projects)
└── pkgs/                       # Downloaded tarballs (cached)
```

## Next Steps

Once gFTP is built successfully:

1. **Test the application** - Run through various FTP operations
2. **Create a macOS app bundle** - Package gFTP as a .app (see gFTP documentation)
3. **Create a DMG installer** - Use `create_dmg_for_app.sh` for distribution
4. **Develop and iterate** - Make changes and rebuild with `jhbuild buildone gftp`

## Additional Resources

- **jhbuild Manual:** https://developer.gnome.org/jhbuild/stable/
- **GTK-OSX Project:** https://gitlab.gnome.org/GNOME/gtk-osx
- **gFTP Repository:** https://github.com/sedwards-ibowl/gftp
- **Meson Build System:** https://mesonbuild.com/
- **GTK3 Documentation:** https://docs.gtk.org/gtk3/
