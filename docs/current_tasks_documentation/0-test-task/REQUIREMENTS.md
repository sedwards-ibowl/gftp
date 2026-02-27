# REQUIREMENTS

Purpose:  
Define **what must be true** for the task to be considered complete.

**Authoritative Location**: `docs/current_tasks_documentation/0-test-task/REQUIREMENTS.md`

This document is:
- Declarative
- Test-oriented
- Solution-agnostic

It describes **outcomes and constraints**, not implementation.
If *how* something is built is described, it does not belong here.

---

## Functional Requirements

- **FR-1:** The gFTP application MUST display appropriate graphical icons for all identified file types (e.g., general file, directory, executable, document, archive) in both the local and remote file views when running on macOS.
- **FR-2:** The gFTP application MUST display appropriate graphical icons for all identified file types in both the local and remote file views when running on Linux.
- **FR-3:** The icons displayed for files and directories MUST accurately reflect their type and be visually distinct to enhance user comprehension.

## Non-Functional Requirements

- **NFR-1 (Compatibility):** All icon assets used for displaying file/folder types MUST be in a format natively supported by GTK3 on both macOS and Linux (e.g., `.png`, `.svg`). Any existing `.xpm` assets currently serving as icons MUST be converted to a supported format.
- **NFR-2 (Maintainability):** The icon assets and their corresponding mapping logic MUST be organized in a clear, consistent, and maintainable manner within the codebase and the build system.
- **NFR-3 (Performance):** The process of loading and displaying icons MUST NOT introduce any perceptible performance degradation or significant increase in application startup time.

## Acceptance Criteria Mapping

- **FR-1:**
    - Verification method: Manual / Inspection
    - Success condition: On macOS, launch the gFTP application. Navigate through various local and remote directories containing different file types. Visually confirm that all common file types and directories (e.g., `.txt`, `.pdf`, `.exe`, folders) display distinct, appropriate icons.
- **FR-2:**
    - Verification method: Manual / Inspection
    - Success condition: On a Linux environment, launch the gFTP application. Navigate through various local and remote directories containing different file types. Visually confirm that all common file types and directories display distinct, appropriate icons.
- **FR-3:**
    - Verification method: Manual / Inspection
    - Success condition: Visually confirm that icons for distinct file types (e.g., a folder icon is different from an executable icon, which is different from a generic text file icon) are clearly distinguishable to the user.
- **NFR-1 (Compatibility):**
    - Verification method: Inspection (Codebase & Build Output)
    - Success condition: Review the gFTP source code and generated application bundle to verify that no `.xpm` files are directly referenced or used for icon display in GTK3 code paths. Confirm that the build system correctly packages and installs icon assets exclusively in supported formats.
- **NFR-2 (Maintainability):**
    - Verification method: Inspection (Codebase & Build System)
    - Success condition: Review the directory structure for icon assets, relevant C code, and Meson build files (`meson.build`) to ensure logical organization, clear naming conventions, and ease of future updates.
- **NFR-3 (Performance):**
    - Verification method: Manual / Observation
    - Success condition: Launch the gFTP application and browse file systems on typical target hardware (macOS and Linux). Observe and confirm that there is no noticeable delay or slowdown during application startup or file/directory navigation directly attributable to icon loading.

## Explicit Non-Requirements

- Not doing: Implementing entirely new file type detection mechanisms that do not currently exist in gFTP.
- Not doing: Undertaking large-scale refactoring of existing gFTP core logic or UI components beyond what is necessary for icon handling.
- Not supporting: Displaying animated icons or advanced icon features not currently present.

## Assumptions

- **Assumption:** The GTK3 API provides standard and functional mechanisms (e.g., `GtkIconTheme`, `GdkPixbuf`) for loading and rendering `.png` and `.svg` image formats as icons within tree views and list boxes.
    - **Impact if false:** Significant, custom image loading and rendering code would need to be developed, increasing complexity and risk.
- **Assumption:** There exist sufficient source icon assets (either current `.xpm` files or other readily available graphical assets) that can be converted or adapted into suitable `.png` or `.svg` formats for all necessary file types.
    - **Impact if false:** New icon assets would need to be designed or externally sourced, potentially introducing delays and design dependencies.
- **Assumption:** The core problem lies primarily with icon format incompatibility or incorrect asset pathing/packaging, and not with fundamental errors in gFTP's UI rendering logic for icons.
    - **Impact if false:** The investigation and fix would involve more complex UI debugging and potentially extensive changes to GTK-related UI code.

## Open Questions

- What specific `Gtk` or `Gdk` functions are currently responsible for loading icon resources based on file type or name? (e.g., `gtk_icon_theme_load_icon`, `gdk_pixbuf_new_from_file`).
- What are the precise file name patterns or conventions that gFTP uses to associate an icon name with a given file type (e.g., "folder.png", "binary.svg", "document-text.png")?
- What toolchain or method should be used for converting existing `.xpm` icon files to `.png` and `.svg` format, ensuring quality and consistency?
- What are the exact installation target paths within the macOS `.app` bundle (and standard Linux installations) that ensure GTK3's icon theme engine (if used) can correctly discover and load the converted icons?
- Are all the necessary visual metaphors for file types (e.g. folder, text, binary, compressed, image) currently represented by existing `.xpm` files, or will some new icons need to be created?


Time Created: 2026-02-22 00:00:00  
Time Modified: 2026-02-22 00:00:00
