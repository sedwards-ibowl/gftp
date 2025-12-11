# gFTP Quick Start Guide - macOS

## 🚀 Quick Start (TL;DR)

```bash
# Build
cd ~/source/jhbuild
jhbuild -f jhbuildrc buildone gftp

# Create App Bundle
cd ~/source/jhbuild/checkout/gftp
./create_app_bundle.sh

# Run
open gFTP.app
```

---

## 📦 What's New

### ✅ All Fixed Issues
1. **Ctrl-C Now Works** - App quits cleanly
2. **Translations Relocatable** - Move app anywhere
3. **SSH/SFTP Works** - No more crashes on connection

### 📍 App Bundle Location
```
~/source/jhbuild/checkout/gftp/gFTP.app
```

---

## 🧪 Testing Checklist

### Test 1: Basic Launch
```bash
open gFTP.app
```
✓ App should launch without errors

### Test 2: Translations
```bash
LANG=es_ES.UTF-8 ./gFTP.app/Contents/MacOS/gftp-gtk
```
✓ Interface should be in Spanish

### Test 3: Ctrl-C Quit
```bash
./gFTP.app/Contents/MacOS/gftp-gtk
# Press Ctrl-C
```
✓ App should quit cleanly (not hang)

### Test 4: SSH/SFTP Connection
```
In gFTP GUI:
1. Protocol: SSH2
2. Host: your-server.com
3. User: your-username
4. Port: 22
5. Click Connect
```
✓ Host key dialog should appear (not crash)

### Test 5: FTP Connection
```
In gFTP GUI:
1. Protocol: FTP
2. Host: ftp.example.com
3. User: anonymous
4. Click Connect
```
✓ Should connect successfully

---

## 📝 Files to Review

| File | Purpose |
|------|---------|
| `FIXES_SUMMARY.md` | Complete technical details of all fixes |
| `README.AppBundle.md` | App bundle implementation details |
| `CHANGELOG.md` | Chronological change log |
| `TODO.txt` | Task completion status |
| `create_app_bundle.sh` | Packaging script |

---

## 🐛 If Something Goes Wrong

### App Won't Launch
```bash
# Check for errors
./gFTP.app/Contents/MacOS/gftp-gtk 2>&1 | tee gftp-errors.log
```

### Translations Not Working
```bash
# Verify locale directory exists
ls -la gFTP.app/Contents/Resources/locale/

# Check specific language
ls -la gFTP.app/Contents/Resources/locale/es/LC_MESSAGES/
```

### SSH/SFTP Still Crashing
```bash
# Check crash logs
cat /Library/Logs/DiagnosticReports/gftp-gtk*.crash
```

### Rebuild Everything
```bash
cd ~/source/jhbuild
jhbuild -f jhbuildrc cleanone gftp
jhbuild -f jhbuildrc buildone gftp
cd ~/source/jhbuild/checkout/gftp
rm -rf gFTP.app
./create_app_bundle.sh
```

---

## 📧 Reporting Issues

If you encounter problems:

1. **Gather Info**:
   - macOS version: `sw_vers`
   - GTK version: `pkg-config --modversion gtk+-3.0`
   - Error messages from terminal
   - Crash logs from Console.app

2. **Check Documentation**:
   - Review `FIXES_SUMMARY.md`
   - Check `README.AppBundle.md`

3. **Test Non-Bundle Version**:
   ```bash
   ~/source/jhbuild/install/bin/gftp-gtk
   ```

---

## 🎯 Next Steps

### Ready for Distribution?

1. **Code Sign** (optional)
   ```bash
   codesign --sign "Developer ID" gFTP.app
   ```

2. **Create DMG** (optional)
   ```bash
   hdiutil create -volname "gFTP" -srcfolder gFTP.app \
     -ov -format UDZO gFTP.dmg
   ```

3. **Notarize** (optional, for macOS 10.15+)
   - Requires Apple Developer account
   - See Apple's notarization guide

### Contributing Back?

All changes are in:
```
~/source/jhbuild/checkout/gftp/
```

Ready to commit or create PR!

---

## ⚡ Performance Tips

- **First Launch**: May be slower (loading libraries)
- **Subsequent Launches**: Should be fast
- **Memory Usage**: ~50-100MB typical
- **SSH Connections**: Add `-v` flag for debug output

---

## 🔧 Advanced Usage

### Custom Locale Directory
```bash
export GFTP_LOCALE_DIR="/custom/path/to/locale"
./gFTP.app/Contents/MacOS/gftp-gtk
```

### Debug Mode
```bash
# Built with GFTP_DEBUG flag enabled
./gFTP.app/Contents/MacOS/gftp-gtk 2>&1 | grep "DEBUG"
```

### Bundle Different Install
```bash
INSTALL_PREFIX="/different/path" ./create_app_bundle.sh
```

---

**Last Updated**: December 12, 2024
**macOS Version Tested**: 15.6.1 (Sequoia)
**GTK Version**: 3.24.51
