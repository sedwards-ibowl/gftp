# TASK PACKET: macOS SMB/CIFS Protocol Support (NetFS Native Bridge)

## Objective
Implement native Windows/Samba (CIFS/SMB) support for gFTP on macOS using the `NetFS` framework. This enables secure, high-performance file transfers with "Zero Regressions" by delegating SMB complexity to the macOS kernel.

## Non-Goals
- Building a standalone `libsmbclient` (deferred to future cross-platform work).
- Supporting SMB1 (deprecated by macOS).
- Implementing Windows-specific features (e.g., Print Shares).

## Constraints
- **Framework**: `NetFS.framework`, `Foundation.framework`, `CoreFoundation.framework`.
- **Language**: Objective-C (with a clean C-interface for gFTP).
- **Architecture**: Protocol Isolation Layer (Plugin Pattern).
- **Target**: macOS 12.0+.

## Exact File Touch List
- **Create**:
  - `lib/protocol_smb_cifs.m` (Final implementation)
  - `lib/auth_smb_cifs.m` (Final implementation)
  - `src/gtk/smb_connect_dialog.c` (Wait dialog)
- **Modify**:
  - `meson.build` (Link frameworks)
  - `lib/meson.build` (Add source files)
  - `src/gtk/meson.build` (Link NetFS)
  - `lib/gftp.h` (Protocol definitions)
  - `lib/protocols.c` (Register protocol)

## Implementation Checklist
- [ ] Update `meson.build` to link `NetFS`, `Foundation`, and `CoreFoundation`.
- [ ] Implement `gftp_macos_smb_connect` using `NetFSMountURLSync` and the provided `openOptions` dictionary.
- [ ] Create a `smb_connect_dialog.c` in GTK to show "Connecting..." with a 10s `g_timeout_add` watchdog.
- [ ] Implement `gftp_macos_smb_disconnect` to clean up mounts on connection close.
- [ ] Map gFTP protocol functions (`get_dir_listing`, `get_file`, `put_file`, `stat`) to `NSFileManager` operations on the discovered `/Volumes/` path.
- [ ] Register `GFTP_PROTOCOL_WINDOWS` (8) in `lib/protocols.c`.

## Acceptance Tests
1. **Connection**: `open gFTP.app` -> Select SMB -> Enter `smb://host/share` -> Verify "Connecting..." dialog appears.
2. **Auth**: Enter correct/incorrect credentials -> Verify mount succeeds or returns specific error code.
3. **List**: Verify remote file list matches the SMB share content.
4. **Transfer**: Perform 1GB bi-directional transfer -> Verify hash integrity.
5. **Timeout**: Simulate slow/unresponsive host -> Verify app aborts after 10s without hanging.

## Open Risks
- **Mount Point Conflicts**: Handling cases where the share is already mounted by the system or another app.
- **Async UI Integration**: Ensuring the background thread for `NetFSMountURLSync` correctly interacts with the GTK main loop.
