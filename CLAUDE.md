# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

gFTP is a multi-threaded GTK+ FTP client supporting FTP, FTPS (explicit and implicit TLS), SFTP (SSH2), HTTP/HTTPS, and local file browsing. It provides both a GTK+ graphical interface and a text-based command-line interface.

**Repository**: https://github.com/sedwards-ibowl/gftp (fork of https://github.com/masneyb/gftp/)
**Version**: 2.9.1b
**Primary Platforms**: Linux (native), macOS (via jhbuild)

## Building

This project uses the Meson build system.

### Standard Build

```bash
# Configure build
meson build

# Build
ninja -C build

# Install
ninja -C build install
```

### Build Options

Configure build options via `-D` flags:

```bash
# Build with GTK3 (default is GTK2)
meson build -Dgtk3=true -Dgtk2=false

# Disable GTK port (text-only)
meson build -Dgtkport=false

# Disable text port
meson build -Dtextport=false

# Build without SSL support
meson build -Dssl=false

# Debug build (enables GFTP_DEBUG macro)
meson build --buildtype=debug
```

See `meson_options.txt` for all available options.

### macOS Build via jhbuild

When building on macOS using jhbuild (native build without Homebrew dependencies):

```bash
# Build using jhbuild
cd ~/source/jhbuild
jhbuild -f jhbuildrc buildone gftp

# Clean and rebuild
jhbuild -f jhbuildrc cleanone gftp
jhbuild -f jhbuildrc buildone gftp

# Update source without building
jhbuild -f jhbuildrc update gftp
```

Installed binaries location: `~/source/jhbuild/install/bin/`

### macOS App Bundle

Create a macOS app bundle:

```bash
cd ~/source/jhbuild/checkout/gftp
./create_app_bundle.sh

# Launch
open gFTP.app
```

See `QUICK_START.md` for detailed testing procedures.

## Running

### GTK+ Interface

```bash
# Auto-detect (runs gftp-gtk if DISPLAY is set, else gftp-text)
gftp

# Force GTK+ version
gftp-gtk

# On macOS app bundle
open gFTP.app
# or
./gFTP.app/Contents/MacOS/gftp-gtk
```

### Text Interface

```bash
# Interactive mode
gftp-text

# Batch download (downloads directory and subdirectories)
gftp-text -d ftp://ftp.example.com/path/to/dir

# Download via SSH/SFTP
gftp-text -d ssh2://user@host.com/path
```

### Debugging

Enable debug output by building with debug mode:

```bash
meson build --buildtype=debug
ninja -C build
```

This defines the `GFTP_DEBUG` macro which enables `DEBUG_PRINT_FUNC` and debug logging throughout the codebase.

### TLS Debugging (FTPS)

Export TLS session keys for Wireshark decryption:

```bash
export SSLKEYLOGFILE=~/gftp_tls_keys.log
gftp

# Then load the keylog file in Wireshark:
# Preferences → Protocols → TLS → (Pre)-Master-Secret log filename
```

See `docs/README.keylog` for detailed SSLKEYLOGFILE usage and live traffic decryption with tshark.

## Architecture

### Directory Structure

```
gftp/
├── lib/                    # Core library (protocol implementations, shared code)
│   ├── gftp.h             # Main header file with data structures
│   ├── options.h          # Global configuration variables
│   ├── protocols.c        # Protocol abstraction layer
│   ├── protocol_ftp.c     # FTP protocol implementation
│   ├── protocol_ftps.c    # FTPS (explicit TLS) implementation
│   ├── protocol_http.c    # HTTP/HTTPS protocol implementation
│   ├── sshv2.c            # SFTP (SSH2) via OpenSSH client
│   ├── protocol_localfs.c # Local filesystem browsing
│   ├── sslcommon.c        # OpenSSL TLS functionality
│   ├── misc.c             # Utility functions
│   ├── config_file.c      # Configuration file parsing
│   └── cache.c            # Directory listing cache
├── src/
│   ├── gftp.in            # Launcher script (auto-detects GUI vs text)
│   ├── uicommon/          # Shared UI code (GTK+ and text)
│   ├── gtk/               # GTK+ interface implementation
│   │   ├── gftp-gtk.c     # Main GTK+ application
│   │   ├── transfer.c     # File transfer UI
│   │   ├── bookmarks.c    # Bookmark management
│   │   └── platform_specific.c  # macOS-specific code
│   └── text/              # Text/CLI interface implementation
│       ├── gftp-text.c    # Main text application
│       └── textui.c       # Text UI callbacks
├── docs/                  # Documentation
├── po/                    # Translations (gettext)
├── icons/                 # Application icons
└── meson.build            # Build configuration
```

### Core Architecture

**Protocol Abstraction**: All protocols implement a common interface defined by the `gftp_request` structure and function pointers in `lib/gftp.h`. Each protocol (FTP, FTPS, SFTP, HTTP, local) implements operations like connect, disconnect, list_files, get_file, put_file, etc.

**Request Structure**: The `gftp_request` struct (in `lib/gftp.h`) represents a connection to a remote (or local) host. It contains:
- Connection state (hostname, port, username, password)
- Protocol-specific data (`protocol_data` void pointer)
- Function pointers for protocol operations
- Configuration options

**Supported Protocols**: Defined in `gftp_protocols[]` array (see `lib/options.h`):
- FTP (`ftp://`) - port 21
- FTPS (`ftps://`) - explicit TLS on port 21
- FTPSi (`ftpsi://`) - implicit TLS on port 990
- SSH2 SFTP (`ssh2://`) - requires OpenSSH `ssh` binary
- HTTP/HTTPS (`http://`, `https://`)
- Local (`file://`)

**Multi-threading**: File transfers run in separate threads (when `use_threads` is enabled for the protocol). The GTK+ UI updates from worker threads via callbacks.

**Configuration**: User settings stored in `${XDG_CONFIG_HOME}/gftp/` (usually `~/.config/gftp/`):
- `gftprc` - Main config file
- `bookmarks` - Saved bookmarks
- `gftp.log` - Application log (auto-purged on startup)

**Caching**: Directory listings are cached (TTL configurable via `cache_ttl` option) to reduce server requests.

### Platform-Specific Code

**macOS Support**:
- `HAVE_COREFOUNDATION` macro enables CoreFoundation framework integration
- Used for app bundle resource path detection (`src/gtk/platform_specific.c`)
- Relocatable locale directory support for app bundles
- Signal handling fixes for Ctrl-C behavior on macOS

### Protocol Implementation Details

**SFTP (SSH2)**: Launches external OpenSSH `ssh` binary as a subprocess using a PTY (`lib/pty.c`). Communicates via stdin/stdout to transfer files and list directories.

**FTPS**: Uses OpenSSL for TLS. Supports both explicit (AUTH TLS on port 21) and implicit (direct TLS on port 990) modes. Can export session keys via SSLKEYLOGFILE for Wireshark decryption.

**FTP**: Pure FTP implementation with active/passive mode support. Directory listing parsing handles various FTP server formats (`lib/ftp-dir-listing.c`).

## Common Development Tasks

### Adding a New Protocol

1. Create `lib/protocol_<name>.c` with protocol implementation
2. Define protocol struct in `lib/options.h` in `gftp_protocols[]` array
3. Implement required function pointers: `init`, `connect`, `disconnect`, `list_files`, `get_file`, `put_file`, etc.
4. Add protocol-specific options to `gftp_global_config_vars` in `lib/options.h`
5. Update `lib/meson.build` to include new source file

### Modifying UI

- **GTK+ UI**: Edit files in `src/gtk/`
  - Main window: `gftp-gtk.c`
  - Transfers: `transfer.c`, `gtkui_transfer.c`
  - Options dialog: `options_dialog.c`
  - Shared GTK/text code: `src/uicommon/gftpui.c`

- **Text UI**: Edit files in `src/text/`
  - Main: `gftp-text.c`
  - UI callbacks: `textui.c`

### Working with Translations

Translations use gettext. Wrap user-facing strings with `_()` or `N_()` macros.

```bash
# Update translation templates
ninja -C build gftp-pot

# Update existing translations
ninja -C build gftp-update-po
```

Translation files: `po/*.po`

### Compatibility Notes

- **OpenSSL**: Assumes OpenSSL 3.0+ (OpenSSL 1.1.1 reached EOL Sept 2023)
- **GTK**: Supports both GTK2 (default) and GTK3 (via build option)
- **C Standard**: C11 (`c_std=c11` in meson.build)
- **macOS**: Requires Xcode Command Line Tools, tested on macOS Sequoia 15.6.1
- **Thread Safety**: Uses `_REENTRANT` define and pthread library

### File Encoding

The codebase uses charset conversion (`lib/charset-conv.c`) to handle different remote character sets. Configure via `remote_charsets` option (comma-separated list).

### Known macOS-Specific Fixes

See `FIXES_SUMMARY.md` and `QUICK_START.md` for recent macOS fixes:
1. Ctrl-C signal handling (prevent hang on quit)
2. Relocatable translation files (app bundle support)
3. SSH/SFTP connection fixes

## Testing

There is no formal test suite. Manual testing checklist in `QUICK_START.md`:

1. Basic launch (GUI and text)
2. Translations (verify locale loading)
3. Ctrl-C quit behavior
4. Protocol connections (FTP, FTPS, SFTP)
5. File transfers (upload/download)
6. Bookmarks
7. App bundle functionality (macOS)

## Configuration Files

Example configuration files are in `docs/sample.gftp/`. These demonstrate the config file format for `gftprc`.

User configuration is NOT stored in the repository - it's in `${XDG_CONFIG_HOME}/gftp/`.

## Additional Documentation

- `README.md` - Basic FAQ and requirements
- `QUICK_START.md` - macOS quick start and testing guide
- `docs/USERS-GUIDE` - End-user documentation
- `docs/README.keylog` - TLS session key logging for debugging
- `docs/gftp.1` - Man page
- `ChangeLog` - Historical change log
- `AUTHORS` - Author and contributor information
