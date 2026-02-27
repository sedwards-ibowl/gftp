# DISCOVERY

Purpose:  
Capture understanding, context, and unknowns **before** committing to
requirements or implementation.

**Authoritative Location**: `docs/current_tasks_documentation/0-test-task/DISCOVERY.md`

This document is **exploratory only**:
- It may contain uncertainty
- It may contain incorrect hypotheses
- It must not prescribe solutions or scope commitments

If certainty exists, it belongs in a later document.

---

## Problem Statement

The gFTP application displays missing icons for files, folders, and binaries, particularly when running on macOS. This visual deficiency impairs the user's ability to quickly identify file types, leading to a degraded user experience. The root cause is believed to be an incompatibility with the `.xpm` icon format on macOS and/or incorrect placement/discovery of icon assets within the application bundle.

## Current Behavior

- Icons are not displayed for various file and folder types in both the local and remote file views within the gFTP application on macOS.
- The application is a C-based GTK3 application, initially developed for Linux and subsequently ported to macOS.
- The `HUMAN_IDEA_BRIEF.md` explicitly states that `.xpm` files are not supported on macOS, even with GTK2 or GTK3.
- The project's `icons/` directory contains various subdirectories for different icon sizes (e.g., `16x16`, `22x22`, `scalable`), which include `gftp.png` and `gftp.svg`.
- The `gftp-install/share/gftp` directory, which is part of the installation structure, also contains several `.xpm` files (e.g., `deb.xpm`, `dir.xpm`, `doc.xpm`, `gftp-logo.xpm`).
- The `gFTP.app/Contents/Resources/share/icons/hicolor` path within the macOS application bundle indicates that some `gftp.png` and `gftp.svg` assets are already packaged.

## Desired Outcome

The discovery process aims to achieve the following:
- A clear understanding of how gFTP's GTK3 interface loads and resolves icons, specifically within the macOS environment.
- Identification of the exact icon files and formats that are currently failing to load.
- Pinpointing the precise locations where icon assets are expected to reside within the macOS application bundle.
- Confirmation of whether all necessary icon assets are present in a supported format, or if conversion/creation of `.png` or `.svg` files from existing `.xpm` files is required.

## Scope Characterization

- [ ] Localized (single component / feature)
- [x] Multi-component (affects UI rendering logic, build system configuration, and asset management)
- [ ] Systemic / cascading
- [ ] Unknown / unclear

## Suspected Root Causes (Optional)

- **Possible cause:** GTK3 on macOS inherently lacks support for the `.xpm` icon format, causing any icons supplied in this format to fail loading.
    - **Supporting observations:** Explicitly stated in the `HUMAN_IDEA_BRIEF.md` that `.xpm` is not supported on macOS.
    - **Contradicting observations:** None.
    - **Confidence level:** High
- **Possible cause:** Icon files, even if in a supported format, are incorrectly located or not properly registered within the macOS application bundle structure, preventing the application from discovering them at runtime.
    - **Supporting observations:** Missing icons despite the presence of `gftp.png` and `gftp.svg` in some `icons/` subdirectories. The `gftp.app` structure exists.
    - **Contradicting observations:** The build system (Meson) generally handles installation paths.
    - **Confidence level:** Medium
- **Possible cause:** The application's internal logic for mapping file types to icon names is flawed or outdated, leading to requests for non-existent or incorrectly named icon assets.
    - **Supporting observations:** None explicit, but a possibility in a legacy application.
    - **Contradicting observations:** The problem is described as "missing icons" rather than "wrong icons."
    - **Confidence level:** Low
- **Possible cause:** Some icon assets for specific file types are entirely missing from the source tree or build output.
    - **Supporting observations:** General statement of "missing icons for files, folders and binaries."
    - **Contradicting observations:** The presence of `deb.xpm`, `dir.xpm`, etc., suggests many basic icons do exist in some format.
    - **Confidence level:** Low

## Open Questions

- What specific GTK+ API (e.g., `GtkIconTheme`, `GtkImage`, `GdkPixbuf`) is used by gFTP to load and display icons in `src/gtk/listbox.c` and `src/uicommon/gftpui.c`?
- What are the standard icon search paths and naming conventions for GTK3 applications within a macOS `.app` bundle?
- Can existing `.xpm` icons be reliably converted to `.png` or `.svg` without loss of quality, or should new vector/high-resolution icons be considered?
- How does the `gftp.desktop` file (located in `docs/` and `install/share/applications/`) relate to icon theme discovery, if at all?
- How are default icons (e.g., for generic files, folders) handled versus specific file type icons (e.g., for `.deb`, `.doc`)?
- What is the exact mapping logic between file extensions/types and the icon files used?

## Notes / Artifacts

- `INTENT_SPEC.md`
- `HUMAN_IDEA_BRIEF.md`
- `PROJECT_CONTEXT.md`
- Initial `ls -RF` output provides a comprehensive file structure overview, including the presence of `*.xpm` and `*.png`/`*.svg` in various `icons/` and `gftp-install/` locations.


Time Created: 2026-02-22 00:00:00  
Time Modified: 2026-02-22 00:00:00
