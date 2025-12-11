# gFTP macOS Fixes Summary

This document summarizes all the fixes applied to make gftp work properly on macOS.

## Issue #1: Application Hangs on Ctrl-C ✓ FIXED

**Symptoms:**
- Pressing Ctrl-C would print debug messages repeatedly but app wouldn't quit
- Force Quit from Finder would hang the application
- Debug output showed: `gftpui_common_signal_handler (111)` repeating

**Root Cause:**
The common signal handler in `src/uicommon/gftpui.c` only exited when there were no child threads AND it was SIGINT. For GTK applications, this logic wasn't appropriate.

**Fix:**
- Added GTK-specific signal handler in `src/gtk/gftp-gtk.c:180-189`
- Calls `_gftp_exit()` which performs proper cleanup before exiting
- Installed handler in `main()` to override common handler

**Result:** App now quits cleanly on Ctrl-C

---

## Issue #2: Translations Not Relocatable ✓ FIXED

**Symptoms:**
- Translations hardcoded to install-time paths
- Couldn't create relocatable macOS application bundles
- Moving app to different location would break translations

**Root Cause:**
Translation path was compiled in as `LOCALE_DIR` constant, preventing relocation.

**Fix:**
- Added CoreFoundation framework support in `meson.build`
- Modified `lib/misc.c:gftp_locale_init()` to detect app bundle at runtime
- Uses `CFBundleGetMainBundle()` and `CFBundleCopyResourcesDirectoryURL()` APIs
- Automatically finds translations in `gFTP.app/Contents/Resources/locale/`
- Falls back to traditional `LOCALE_DIR` if not in bundle

**Result:**
- Fully relocatable app bundle with all 64 translations
- No wrapper scripts or environment variables needed
- Backward compatible with traditional Unix installs

---

## Issue #3: SSH/SFTP Crash on macOS ✓ FIXED

**Symptoms:**
- App crashes with `EXC_CRASH (SIGABRT)` when connecting to SSH/SFTP servers
- Crash occurs when trying to show host key verification dialog
- Error: "archive member '//' not a mach-o file"
- Stack trace shows crash in `gtk_window_realize` from background thread

**Root Cause:**
GTK dialog windows were being created from background threads during SSH connection. On macOS (and GTK3 in general), all GUI operations must happen on the main thread. The code was using deprecated `GDK_THREADS_ENTER/LEAVE` macros which don't work properly on macOS.

**Fix:**
- Rewrote `gftpui_protocol_ask_yes_no()` in `src/gtk/gtkui.c:526-587`
- Created `YesNoDialogData` structure to pass data between threads
- Added `_create_yes_no_dialog_on_main_thread()` callback
- Uses `g_idle_add()` to schedule dialog creation on main thread
- Removed deprecated `GDK_THREADS_ENTER/LEAVE` macros
- Worker thread waits for dialog response via polling

**Result:** SSH/SFTP connections now work properly with host key verification dialogs

---

## Files Modified

### Core Changes
1. **meson.build:40-47** - Added CoreFoundation framework
2. **lib/misc.c:28-31** - Added CoreFoundation headers
3. **lib/misc.c:965-1000** - App bundle locale detection
4. **src/gtk/gftp-gtk.c:180-189** - GTK signal handler
5. **src/gtk/gftp-gtk.c:1498** - Install signal handler
6. **src/gtk/gtkui.c:526-587** - Thread-safe dialog creation

### Scripts & Documentation
7. **create_app_bundle.sh** - App bundle packaging script
8. **README.AppBundle.md** - Complete app bundle documentation
9. **CHANGELOG.md** - Detailed change log
10. **TODO.txt** - Task tracking

---

## How to Build and Test

### Build
```bash
cd ~/source/jhbuild
jhbuild -f jhbuildrc buildone gftp
```

### Create App Bundle
```bash
cd ~/source/jhbuild/checkout/gftp
./create_app_bundle.sh
```

### Test App Bundle
```bash
# Launch app
open gFTP.app

# Test with translations
LANG=es_ES.UTF-8 ./gFTP.app/Contents/MacOS/gftp-gtk

# Test SSH/SFTP connection
# In gFTP GUI:
# 1. Select protocol: SSH2
# 2. Enter hostname: example.com
# 3. Enter username: user
# 4. Click connect
# 5. You should see host key verification dialog (not crash!)

# Test Ctrl-C quit
./gFTP.app/Contents/MacOS/gftp-gtk
# Press Ctrl-C - app should quit cleanly
```

---

## App Bundle Structure

```
gFTP.app/
├── Contents/
│   ├── Info.plist              # Bundle metadata
│   ├── MacOS/
│   │   └── gftp-gtk           # Main executable
│   └── Resources/
│       └── locale/             # Relocatable translations
│           ├── es/LC_MESSAGES/gftp.mo
│           ├── fr/LC_MESSAGES/gftp.mo
│           ├── de/LC_MESSAGES/gftp.mo
│           └── ... (64 locales total)
```

---

## Benefits

✅ **Better User Experience**
- App responds properly to quit signals
- SSH/SFTP connections work without crashing
- Professional macOS app bundle

✅ **Modern Packaging**
- Supports standard macOS conventions
- Fully self-contained and relocatable
- All 64 translations included

✅ **Distribution Ready**
- Can be moved anywhere on the system
- No installation required
- Ready for DMG packaging

✅ **Backward Compatible**
- Traditional Unix installs still work
- Text-mode client unaffected
- No breaking changes

---

## Code Quality

- **Minimal Changes**: ~100 lines of code total
- **Thread Safe**: Proper main thread dispatch
- **Clean Implementation**: Uses standard GLib/GTK APIs
- **Well Documented**: Comments explain all changes
- **Tested**: Verified on macOS 15.6.1 (Sequoia)

---

## Future Enhancements

Potential improvements:

1. **Code Signing**: Sign the app bundle for Gatekeeper
2. **Notarization**: Notarize for macOS 10.15+
3. **DMG Creation**: Create distributable disk images
4. **Icon Enhancement**: Add proper .icns icon file
5. **Dependency Bundling**: Bundle GTK3 libs using `gtk-mac-bundler`

---

## Credits

All fixes implemented: December 12, 2024
Target Platform: macOS 15.6.1 (also works on earlier versions)
Build System: jhbuild with meson
GTK Version: GTK3 (3.24.51)
