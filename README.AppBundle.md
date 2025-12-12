# gFTP macOS App Bundle with Relocatable Translations

This document describes the implementation of relocatable translations for gFTP on macOS using app bundles.

## Overview

gFTP now supports automatic detection and loading of translations from a macOS application bundle. When running from `gFTP.app`, the application will automatically find translations in the bundle's Resources directory without requiring hardcoded paths.

## Implementation Details

### Runtime Detection

The implementation uses CoreFoundation APIs to detect if the application is running from an app bundle:

1. **CoreFoundation Integration** (`meson.build`)
   - Added `appleframeworks` dependency with CoreFoundation module
   - Defines `HAVE_COREFOUNDATION` when available

2. **Locale Directory Detection** (`lib/misc.c:gftp_locale_init()`)
   - Uses `CFBundleGetMainBundle()` to get the bundle reference
   - Uses `CFBundleCopyResourcesDirectoryURL()` to find Resources directory
   - Constructs path to `Resources/locale` directory
   - Falls back to compile-time `LOCALE_DIR` if not in a bundle or path doesn't exist

### App Bundle Structure

```
gFTP.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── gftp-gtk                 (executable)
│   └── Resources/
│       └── locale/
│           ├── es/LC_MESSAGES/gftp.mo
│           ├── fr/LC_MESSAGES/gftp.mo
│           ├── de/LC_MESSAGES/gftp.mo
│           └── ... (64 locales total)
```

## Building and Packaging

### Step 1: Build gFTP

```bash
cd ~/source/jhbuild
jhbuild -f jhbuildrc buildone gftp
```

This will:
- Build gftp-gtk with CoreFoundation support
- Install to `~/source/jhbuild/install/`
- Build all translation files (*.mo) to `install/share/locale/`

### Step 2: Create App Bundle

```bash
cd ~/source/jhbuild/checkout/gftp
./create_app_bundle.sh
```

This will:
- Create `gFTP.app` in the current directory
- Copy the gftp-gtk binary to `Contents/MacOS/`
- Copy all 64 translation files to `Contents/Resources/locale/`
- Generate `Info.plist` with app metadata

## Testing

### Test App Bundle Launch

```bash
# Open with Finder
open gFTP.app

# Or run directly
./gFTP.app/Contents/MacOS/gftp-gtk
```

### Test Translation Loading

```bash
# Test Spanish translations
LANG=es_ES.UTF-8 ./gFTP.app/Contents/MacOS/gftp-gtk

# Test French translations
LANG=fr_FR.UTF-8 ./gFTP.app/Contents/MacOS/gftp-gtk

# Test German translations
LANG=de_DE.UTF-8 ./gFTP.app/Contents/MacOS/gftp-gtk
```

The application will automatically detect it's running from a bundle and load translations from `Contents/Resources/locale/`.

## Benefits

1. **Relocatable**: App bundle can be moved anywhere without breaking translations
2. **Self-contained**: All translations included in the bundle
3. **Backward Compatible**: Still works with traditional Unix installations
4. **No Scripts Required**: No wrapper scripts needed to set environment variables
5. **Minimal Code Changes**: Only ~30 lines of code added

## Files Modified

1. `meson.build` - Added CoreFoundation framework dependency
2. `lib/misc.c` - Added app bundle detection in `gftp_locale_init()`
3. `create_app_bundle.sh` - New script to create app bundles

## Future Enhancements

Potential improvements for the future:

1. **Icon Support**: Add proper .icns icon file
2. **DMG Packaging**: Create distributable DMG images
3. **Code Signing**: Sign the app bundle for Gatekeeper
4. **Notarization**: Notarize for macOS 10.15+
5. **Dependencies**: Bundle GTK3 and other dependencies using tools like `gtk-mac-bundler`

## References

- [Apple Bundle Programming Guide](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/)
- [CoreFoundation Framework](https://developer.apple.com/documentation/corefoundation)
- [GNU gettext](https://www.gnu.org/software/gettext/manual/gettext.html)
