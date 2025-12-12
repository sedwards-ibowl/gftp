# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

gFTP is a multi-protocol file transfer client for Unix-like systems with both GTK+ GUI and text-based interfaces. It supports FTP, FTPS (explicit and implicit TLS), SSH2/SFTP, HTTP/HTTPS, and local filesystem operations.

## Build System

gFTP uses Meson as its build system.

### Building from Source

```bash
# Configure build with defaults (GTK2, text port, SSL enabled)
meson build

# Build
ninja -C build

# Install
ninja -C build install

# Clean and rebuild a specific module
rm -rf build
meson build
ninja -C build
```

### Build Options

Configure build options using `-D` flags with meson:

```bash
# Build with GTK3 instead of GTK2
meson build -Dgtk3=true -Dgtk2=false

# Build only text port (no GUI)
meson build -Dgtkport=false -Dtextport=true

# Disable SSL support
meson build -Dssl=false

# Debug build (enables GFTP_DEBUG macro)
meson build --buildtype=debug
```

Available options (see `meson_options.txt`):
- `gtk3` / `gtk2`: Choose GTK version (default: gtk2=true)
- `gtkport`: Enable GTK GUI (default: true)
- `textport`: Enable text/CLI interface (default: true)
- `ssl`: Enable OpenSSL support (default: true)

### Running Without Installing

```bash
# Run GTK version directly
./build/src/gtk/gftp-gtk

# Run text version directly
./build/src/text/gftp-text

# Run with specific protocol
./build/src/text/gftp-text -d ftp://ftp.example.com/path
./build/src/text/gftp-text -d ssh2://user@host/path

# The gftp wrapper script (generated from src/gftp.in) chooses the appropriate version
# based on DISPLAY environment variable
```

## Architecture

### Core Components

1. **libgftp** (`lib/`): Core protocol engine and utilities
   - `protocols.c`: Protocol registration and management
   - `protocol_*.c`: Individual protocol implementations (FTP, FTPS, SSH2, HTTP, LocalFS)
   - `config_file.c`: Configuration file parsing and management
   - `misc.c`: Utility functions
   - `sslcommon.c`: OpenSSL integration (FTPS support)
   - `sshv2.c`: SSH2/SFTP protocol via OpenSSH subprocess
   - `cache.c`: Directory listing cache
   - `socket-connect.c`: Network connection handling
   - `sockutils.c`: Socket I/O utilities with SSL support

2. **libgftpui** (`src/uicommon/`): UI-independent transfer logic
   - `gftpui.c`: File transfer queue and operations
   - `gftpuicallbacks.c`: UI callback handlers

3. **GTK Port** (`src/gtk/`): GTK+ graphical interface
   - `gftp-gtk.c`: Main GTK application entry point
   - `gtkui.c`: UI initialization and main window
   - `transfer.c`: Transfer window and operations
   - `gtkui_transfer.c`: GTK-specific transfer UI logic
   - `bookmarks.c`: Bookmark manager UI
   - `bookmarks_edit_entry.c`: Bookmark editing dialogs
   - `listbox.c`: File list view management
   - `menu-items.c`: Menu and toolbar actions
   - `options_dialog.c`: Preferences/settings dialog
   - `chmod_dialog.c`: File permissions dialog
   - `view_dialog.c`: File viewer dialog
   - `dnd.c`: Drag-and-drop support
   - `platform_specific.c`: Platform-specific GTK code

4. **Text Port** (`src/text/`): Command-line interface
   - `gftp-text.c`: CLI application entry point
   - `textui.c`: Text UI commands and interface

### Protocol System

Protocols are registered in a static array in `lib/options.h` (line 261):

```c
supported_gftp_protocols gftp_protocols[] = {
  // name      init         register options         url_prefix  dport  shown  use_threads
  { "FTP",     ftp_init,    ftp_register_module,    "ftp",      21,    1,     1 },
  { "FTPS",    ftps_init,   ftps_register_module,   "ftps",     21,    1,     1 },
  { "FTPSi",   ftpsi_init,  ftpsi_register_module,  "ftpsi",    990,   1,     1 },
  { "LocalFS", localfs_init, localfs_register_module, "file",    0,     1,     0 },
  { "SSH2",    sshv2_init,  sshv2_register_module,  "ssh2",     22,    1,     1 },
  { "Bookmark", bookmark_init, bookmark_register_module, "bookmark", 0,  0,     0 }, // hidden
  { "HTTP",    http_init,   http_register_module,   "http",     80,    0,     1 }, // hidden
  { "HTTPS",   https_init,  https_register_module,  "https",    443,   0,     1 }, // hidden
  { NULL, NULL, NULL, NULL, 0, 0, 0 }
};
```

Fields:
- `shown`: Whether protocol appears in UI selection (0=hidden)
- `use_threads`: Whether protocol uses multi-threading for transfers

Each protocol implements the `gftp_request` interface defined in `lib/gftp.h`:
- `init`: Initialize protocol-specific request
- `connect`: Establish connection
- `disconnect`: Close connection
- `list_files`: Get directory listing
- `get_file`: Download file
- `put_file`: Upload file
- `chdir`: Change directory
- Other file operations (chmod, rename, delete, etc.)

Protocol constants are defined as macros:
- `GFTP_PROTOCOL_FTP` (0)
- `GFTP_PROTOCOL_FTPS` (1)
- `GFTP_PROTOCOL_FTPSi` (2)
- `GFTP_PROTOCOL_LOCALFS` (3)

### Configuration System

gFTP uses a hash table-based configuration system:
- Global options: `gftp_global_options_htable`
- Per-protocol options: Registered via `register_options()` callbacks
- Configuration file: `${XDG_CONFIG_HOME}/gftp/gftprc` (usually `~/.config/gftp/gftprc`)
- Bookmarks: `${XDG_CONFIG_HOME}/gftp/bookmarks`

Configuration is loaded at startup via `lib/config_file.c`.

### Threading Model

- Each protocol declares if it uses threads (`use_threads` field)
- File transfers run in separate threads when supported
- GTK UI uses thread-safe callbacks via `gftpui_*` functions
- Text port runs single-threaded

## Protocol-Specific Notes

### FTP/FTPS
- Supports both passive (PASV/EPSV) and active (PORT) modes
- FTPS: Explicit TLS on port 21 (AUTH TLS)
- FTPSi: Implicit TLS on port 990
- Supports MLSD for modern directory listings
- IPv4/IPv6 support via EPSV/EPRT (RFC 2428)
- Directory listing parser handles various FTP server formats (`lib/ftp-dir-listing.c`)

### SSH2/SFTP
- Uses external OpenSSH `ssh` command as subprocess
- PTY management in `lib/pty.c`
- Requires OpenSSH client installed on system
- URL scheme: `ssh2://user@host/path`

### HTTP/HTTPS
- Limited support: CLI download only, no directory listing
- Not shown in protocol selection UI (hidden protocols)
- Useful for downloading single files via `gftp-text`

### SSL/TLS Support
- Requires OpenSSL (assumes OpenSSL 3.0+)
- SSLKEYLOGFILE environment variable supported for TLS debugging (see `docs/README.keylog`)
- Session key logging for Wireshark decryption
- Implemented in `lib/sslcommon.c`

## macOS-Specific Build

This repository is built as part of a jhbuild setup for native macOS:
- Uses system clang and macOS SDK (no Homebrew dependencies)
- Build requires Xcode Command Line Tools
- Meson configuration in `meson.build` includes macOS-specific flags (e.g., `-DHAVE_GRANTPT` for Unix98 PTY support)
- Portable app bundle can be created via `docs/create_portable_gftp.sh`

### Creating a macOS DMG Installer

Use the `create_dmg_for_app.sh` script to create a distributable DMG installer:

```bash
# If gFTP.app is in a standard location (Desktop, current dir, or build/)
./create_dmg_for_app.sh

# Or specify a custom path to the app bundle
./create_dmg_for_app.sh /path/to/gFTP.app
```

The script will:
- Search for `gFTP.app` in common locations (Desktop, current directory, build directory)
- Create a temporary directory with the app bundle and source code
- Generate a compressed DMG file (`gFTP.dmg`) for distribution
- Clean up temporary files

For complete jhbuild setup instructions, see `JHBUILD.md` in the repository root.

## Debugging

### Debug Mode

Build with debug symbols and enable debug output:

```bash
meson build --buildtype=debug
ninja -C build
```

When built with debug mode, debug macros are enabled:
- `DEBUG_PRINT_FUNC`: Prints function entry
- `DEBUG_MSG(x)`: Prints debug message
- `DEBUG_TRACE(format, ...)`: Printf-style debug output

### SSL/TLS Debugging

Export TLS session keys for Wireshark decryption:

```bash
export SSLKEYLOGFILE=~/gftp_tls_keys.log
gftp-gtk
```

See `docs/README.keylog` for detailed instructions on using Wireshark to decrypt FTPS traffic.

### Common Debug Tasks

```bash
# Check build configuration
meson introspect build --buildoptions

# Run with verbose output (text port)
gftp-text --help  # See available options

# View configuration
cat ~/.config/gftp/gftprc

# View logs
tail -f ~/.config/gftp/gftp.log
```

## Code Structure Guidelines

### Adding a New Protocol

1. Create `lib/protocol_newproto.c` with protocol implementation
2. Define init function and protocol operations (connect, list_files, etc.)
3. Create `protocol_newproto_register_module()` for protocol options
4. Add protocol entry to `gftp_protocols[]` array in `lib/options.h`
5. Add protocol constant macro to `lib/gftp.h`
6. Add source file to `lib/meson.build`
7. Update protocol-specific headers if needed

### File Transfer Flow

1. User initiates transfer via UI (GTK or text)
2. UI calls `gftpui_*` functions in `src/uicommon/gftpui.c`
3. Transfer queued in global `gftp_file_transfers` list
4. Transfer thread spawned (if protocol supports threads)
5. Protocol-specific `get_file()`/`put_file()` called
6. Progress updates via UI callbacks
7. Transfer completion logged and UI notified

### GTK Compatibility

- `src/gtkcompat.h`: Macros for GTK2/GTK3 API compatibility
- Code should work with both GTK2 and GTK3
- Conditional compilation based on GTK version macros

## Important Files

- `lib/gftp.h`: Main header with core types and function declarations
- `lib/options.h`: Protocol registration array and global configuration variables
- `lib/protocols.c`: Protocol management and common operations
- `src/gftp.in`: Template for gftp wrapper shell script (configured during build)
- `meson.build`: Main build configuration
- `meson_options.txt`: Build option definitions
- `ChangeLog`: Detailed change history and release notes
- `docs/USERS-GUIDE`: End-user documentation
- `docs/README.keylog`: TLS debugging documentation
- `docs/gftp.1`: Man page

## Recent Changes (from ChangeLog)

Version 2.9.1b:
- Fixed critical segfault in FTP protocol
- Fixed compatibility with broken servers
- General regression fixes

Version 2.9.0b:
- Project relicensed to MIT
- Added FTPSi (Implicit TLS) support on port 990
- Added MLSD support for modern FTP servers
- Fixed IPv6 support
- Fully implemented RFC 2428 (EPSV/EPRT)
- New `ip_version` option (any/ipv4/ipv6)
- Added SSLKEYLOGFILE support for TLS debugging
- Removed FSP support
- Now requires GLIB >= 2.32
- Follows XDG Base Directory Specification for config files
