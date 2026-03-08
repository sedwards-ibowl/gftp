# TASK PACKET: macOS Platform Review and Adaptation

## Objective
Systematically review and adapt the `lib` and `src` directories to ensure full compatibility and idiomatic behavior on the macOS platform. This includes standardizing paths, handling macOS-specific filesystem quirks, and ensuring the UI respects macOS conventions.

## Non-Goals
- Resuming SMB/CIFS implementation (currently ON HOLD).
- Porting to GTK4.
- Changing core protocol logic unless platform-breaking.

## Constraints
- **Target Path**: `~/Library/gFTP` for all user configuration.
- **Frameworks**: Must use Foundation/AppKit via Objective-C wrappers where appropriate.
- **Zero Regressions**: Existing FTP/SSH functionality must remain identical on other platforms.

## Exact File Touch List
- **Modify**:
  - `lib/misc.c` (Further path audits)
  - `lib/config_file.c` (Audit for hardcoded paths)
  - `src/gtk/platform_specific.c` (Enhance native integration)
  - `build_gftp_homebrew.sh` (Ongoing build fixes)

## Implementation Checklist
- [x] Standardize `BASE_CONF_DIR` to `~/Library/gFTP` in `lib/misc.c`.
- [x] Audit `lib/config_file.c` for any remaining hardcoded `~/.gftp` or `~/.config` references.
- [x] Review `src/gtk/` for hardcoded keybindings that conflict with macOS system shortcuts.
- [x] Ensure `gftp-text` (CLI) also respects the `~/Library/gFTP` path on macOS.
- [x] Verify that first-run resource copying logic works correctly for the new path.

## Acceptance Tests
1. **Config Path**: `open gFTP.app` -> Verify `~/Library/gFTP/gftprc` is created and used.
2. **CLI Consistency**: Run `./gftp-text` -> Verify it uses `~/Library/gFTP/` instead of `~/.gftp/`.
3. **Clean Rule**: Run `./build_gftp_homebrew.sh clean` -> Verify all artifacts (including .icns) are removed.
