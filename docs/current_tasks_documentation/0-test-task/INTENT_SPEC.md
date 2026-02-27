# Intent Specification

**TASK:** Fix missing icons for files, folders, and binaries.

## 1. Desired Outcome

- All files and folders in the local file view display the correct icons.
- All files and folders in the remote file view display the correct icons.

## 2. Technical Requirements & Constraints

### Requirements

- **Icon format:** The application must be able to load and display icons. Existing `.xpm` icons **must be converted** to a format compatible with GTK3 on macOS, such as `.png` or `.svg`, as `.xpm` files are not supported on macOS (even with GTK2 or higher).
- **Icon discovery:** The application must be able to locate the icon files within the macOS application bundle.
- **File-type to icon mapping:** The application must correctly map file types (e.g., directory, binary, text file) to their corresponding icons.
- **Platform compatibility:** The solution must work on both macOS and Linux.

### Constraints

- The fix should not introduce any new features or major refactoring.
- The fix should not significantly impact the application's performance.

## 3. Gaps & Ambiguities

- The exact location where the application expects to find the icon files is unknown.
- The list of all required icons and their corresponding file types is not fully defined.

## 4. System Interaction Points

The following parts of the system are likely to be affected:

- **`src/gtk/listbox.c`:** This file likely contains the logic for rendering the file and folder list, including the icons.
- **`src/uicommon/gftpui.c`:** This file might contain common UI code, including functions for loading icons.
- **`meson.build`:** The build script will likely need to be modified to include the icon files in the application bundle and install them in the correct location.
- **`icons/` directory:** This directory contains the application's icons.

## 5. High-Level Plan

1. **Investigate icon loading:** Analyze the source code to determine how icons are loaded and where the application expects to find them.
2. **Convert icons:** Convert existing `.xpm` icons to `.png` or `.svg` formats.
3. **Update build scripts:** Modify the `meson.build` files to ensure that the converted icon files are included in the application bundle in the correct location.
4. **Modify source code:** If necessary, modify the source code to point to the correct icon location and use the correct icon format.
5. **Test:** Verify that the icons are displayed correctly on both macOS and Linux.