# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

gFTP is a multi-protocol file transfer client supporting FTP, FTPS (Explicit and Implicit TLS), SSH2 SFTP, FSP, HTTP/HTTPS, and local filesystem operations. It includes both a GTK+ graphical interface and a text-based CLI interface.

## Build System

gFTP uses Meson build system:

```bash
# Initial setup
meson build

# Build
ninja -C build

# Install
ninja -C build install

# Debug build (enables GFTP_DEBUG macro)
meson build --buildtype=debug
ninja -C build
```

### Build Options

Configure in `meson_options.txt`:
- `gtk2` (default: true): Enable GTK2 support
- `gtk3` (default: false): Enable GTK3 support (mutually exclusive with gtk2)
- `gtkport` (default: true): Build GTK UI
- `textport` (default: true): Build text UI
- `ssl` (default: true): Enable OpenSSL support

To configure custom options:
```bash
meson build -Dgtk3=true -Dgtk2=false
```

## Executables

- `gftp` - Shell script that launches gftp-gtk or gftp-text based on DISPLAY environment variable
- `gftp-gtk` - GTK+ graphical interface
- `gftp-text` - Text-based CLI (supports batch downloads: `gftp-text -d ftp://host/path`)

## Architecture

### Directory Structure

- `lib/` - Core protocol implementations and shared library code
  - `protocol_*.c` - Protocol-specific implementations (FTP, FTPS, HTTP, SSH2, LocalFS)
  - `protocols.c` - Protocol framework and request/file management
  - `config_file.c` - Configuration and bookmarks management
  - `sslcommon.c` - OpenSSL/TLS support (SSLKEYLOGFILE support for debugging)
  - `sshv2.c` - SSH2 SFTP via OpenSSH client subprocess
  - `gftp.h` - Main header with core data structures
  - `options.h` - Global configuration variables and protocol registry

- `src/gtk/` - GTK+ UI implementation
  - `gftp-gtk.c` - Main GTK application
  - `transfer.c` - File transfer UI and management
  - `bookmarks.c` - Bookmark editor
  - `misc-gtk.c` - GTK utility functions

- `src/text/` - Text UI implementation
  - `gftp-text.c` - Main text application
  - `textui.c` - Text UI functions

- `src/uicommon/` - Shared UI code
  - `gftpui.c` - Common UI logic for transfers and operations

### Protocol System

Protocols are registered in `lib/options.h` in the `gftp_protocols[]` array. Each protocol has an ID defined in `lib/gftp.h`:

```c
#define GFTP_PROTOCOL_FTP         0
#define GFTP_PROTOCOL_FTPS        1
#define GFTP_PROTOCOL_FTPSi       2  // Implicit TLS (port 990)
#define GFTP_PROTOCOL_LOCALFS     3
#define GFTP_PROTOCOL_SSH2        4
#define GFTP_PROTOCOL_BOOKMARK    5
#define GFTP_PROTOCOL_HTTP        6
#define GFTP_PROTOCOL_HTTPS       7
```

Each protocol implements the `supported_gftp_protocols` structure with:
- `init()` - Initialize protocol-specific request
- `register_options()` - Register protocol configuration options
- URL prefix, default port, visibility flags

### Request System

The `gftp_request` structure (defined in `lib/gftp.h`) is the central abstraction for all operations. It contains:
- Connection state (hostname, username, password, datafd)
- Protocol-specific function pointers (connect, disconnect, get_file, put_file, list_files, etc.)
- Configuration options (local_options_vars, local_options_hash)
- Character encoding conversion (iconv_to, iconv_from)

Protocol implementations populate these function pointers in their `init()` functions.

### Configuration System

Configuration uses a typed variable system (`gftp_config_vars` in `lib/gftp.h`):
- Global config in `gftp_global_config_vars[]` in `lib/options.h`
- Per-protocol options registered via `register_options()` callbacks
- Bookmarks stored in `${XDG_CONFIG_HOME}/gftp/bookmarks`
- Main config in `${XDG_CONFIG_HOME}/gftp/gftprc`
- Log file at `${XDG_CONFIG_HOME}/gftp/gftp.log`

### TLS/SSL Support

When compiled with `USE_SSL`:
- FTPS (Explicit TLS on port 21) and FTPSi (Implicit TLS on port 990) available
- Implementation in `lib/sslcommon.c` and `lib/protocol_ftps.c`
- Requires OpenSSL 3.0+ (OpenSSL 1.1.1 support was removed after its EOL)
- Supports `SSLKEYLOGFILE` environment variable for TLS session key logging (for Wireshark decryption)
- See `docs/README.keylog` for TLS debugging details

### SSH2 SFTP Implementation

SSH2 protocol in `lib/sshv2.c` works by:
- Spawning OpenSSH `ssh` client as a subprocess
- Using PTY for interaction
- Sending SFTP protocol commands over the SSH connection
- Does NOT link against libssh2 - requires external `ssh` binary

### File Extension System

File transfer modes (ASCII vs Binary) are controlled by extension mappings in config file. Format in gftprc:
```
ext=.html:world.xpm:A:
ext=.jpg:image.xpm:B:
```
Third field: A=ASCII, B=Binary

## Common Development Tasks

### Adding Debug Output

Debug mode is controlled by `GFTP_DEBUG` macro (enabled with `--buildtype=debug`):
```c
DEBUG_PRINT_FUNC          // Print function name and location
DEBUG_MSG("message")      // Print message
DEBUG_TRACE("fmt", ...)   // Printf-style trace
DEBUG_PUTS("string")      // Print string
```

### Adding a New Protocol

1. Create `lib/protocol_newproto.c` with init and register functions
2. Add protocol ID constant in `lib/gftp.h` (protocol definitions section)
3. Add entry to `gftp_protocols[]` array in `lib/options.h`
4. Implement required functions in `gftp_request` structure
5. Add function declarations in `lib/gftp.h`
6. Update `lib/meson.build` to include new source file

### Working with Bookmarks

Bookmarks use a hierarchical tree structure (`gftp_bookmarks_var` in `lib/gftp.h`):
- Folders use forward slashes in path (e.g., "Sites/Debian")
- Global bookmarks root is `gftp_bookmarks`
- Hash table lookup via `gftp_bookmarks_htable`
- Implementation in `lib/config_file.c`

## Important Notes

- All file I/O uses 64-bit offsets (`_FILE_OFFSET_BITS 64`)
- Character encoding conversion available via `gftp_string_from_utf8()` and related functions
- The project follows XDG Base Directory Specification for config files
- Protocol implementations should handle both IPv4 and IPv6 (configurable via `network_protocol` option)
- FTP passive mode vs active mode controlled by `passive_transfer` option
