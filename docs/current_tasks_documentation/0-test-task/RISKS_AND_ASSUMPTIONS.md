# RISKS AND ASSUMPTIONS

Purpose:  
Explicitly surface uncertainties that could affect correctness, scope,
timeline, or stability.

**Authoritative Location**: `docs/current_tasks_documentation/0-test-task/RISKS_AND_ASSUMPTIONS.md`

This document exists to:
- Prevent silent failure modes
- Make fragility visible early
- Enable informed go / no-go decisions

It does NOT define requirements or implementation plans.

---

## Risks

- **Risk:** Converted icon assets from `.xpm` files might suffer from poor visual quality (e.g., blurriness, pixelation) when scaled or displayed on high-resolution screens.
    - **Impact:** Medium (degraded user experience, potential need for redesign or sourcing of new icon sets).
    - **Likelihood:** Medium (`.xpm` is an older, often low-resolution format).
    - **Mitigation or monitoring:** Implement a quality review process for all converted icons. Research and consider open-source GTK-compatible icon sets if conversions are unsatisfactory.
- **Risk:** The GTK3 icon loading mechanism within a macOS application bundle (`.app` structure) may have specific requirements or conventions that differ significantly from standard Linux GTK3 installations, leading to continued icon display issues.
    - **Impact:** High (the core problem of missing icons may persist, requiring extensive investigation and rework).
    - **Likelihood:** Medium (UI toolkit behaviors can vary across OSes, especially with packaging).
    - **Mitigation or monitoring:** Prioritize detailed investigation into GTK3's icon discovery paths on macOS early in the implementation phase. Leverage macOS-specific debugging tools for path resolution.
- **Risk:** The codebase's logic for mapping file types (extensions, MIME types) to specific icon names might be fragmented, implicit, or difficult to reliably extract, leading to an incomplete icon display fix.
    - **Impact:** Medium (some file types may still lack appropriate icons after the fix).
    - **Likelihood:** Medium (common in older, evolving C codebases).
    - **Mitigation or monitoring:** A dedicated code audit of relevant UI and utility files (`src/gtk/listbox.c`, `src/uicommon/gftpui.c`, `lib/config_file.c`, etc.) to exhaustively identify icon mapping logic.
- **Risk:** Modifying the Meson build system to correctly package and install icon assets within the macOS `.app` bundle, while also ensuring correct installation on Linux, proves to be complex or error-prone.
    - **Impact:** Medium (delays in build process, potential for broken builds or incomplete installations).
    - **Likelihood:** Medium (Meson configuration for platform-specific packaging can be nuanced).
    - **Mitigation or monitoring:** Consult Meson documentation specifically for macOS bundling and cross-platform asset management. Create isolated build tests for icon packaging.

---

## Assumptions

- **Assumption:** The core GTK3 framework, as used by gFTP, can successfully load and render `.png` and `.svg` icon formats.
    - **Rationale:** `.png` and `.svg` are widely supported modern image formats in GTK3 across platforms.
    - **Impact if incorrect:** The fundamental approach to icon display would need re-evaluation, possibly requiring different image libraries or rendering techniques.
- **Assumption:** The existing gFTP codebase contains logic to determine a file's type (e.g., based on extension or MIME type) and request a corresponding icon name, even if the current implementation fails to display the icon.
    - **Rationale:** The problem is described as "missing icons," implying that the application *tries* to show icons, just fails to render them.
    - **Impact if incorrect:** A new subsystem for file type detection and icon mapping would need to be implemented, significantly increasing scope.
- **Assumption:** It is feasible to convert existing `.xpm` assets into high-quality `.png` or `.svg` alternatives, or suitable replacement icons can be easily sourced or created.
    - **Rationale:** Standard image conversion tools are available, and generic icon sets often exist.
    - **Impact if incorrect:** May require significant graphic design effort or compromise on visual quality.
- **Assumption:** The `meson.build` files provide sufficient flexibility to define platform-specific installation paths and bundling rules for icon assets without major structural changes to the build system.
    - **Rationale:** Meson is a modern build system designed for flexibility and cross-platform development.
    - **Impact if incorrect:** Custom scripting or build system extensions might be necessary, adding complexity.

---

## Open Questions

- What are the specific GTK3 API calls (functions, properties) used by gFTP that handle icon loading and rendering in `src/gtk/listbox.c` and `src/uicommon/gftpui.c`? (e.g. `gtk_icon_theme_lookup_icon`, `gdk_pixbuf_new_from_file`).
- What is the most appropriate and officially recommended location within a macOS `.app` bundle for GTK3 application icons, and how should `meson.build` target this path?
- Which tool(s) (e.g., ImageMagick, Inkscape) are recommended for converting `.xpm` files to `.png` and `.svg` while preserving or improving quality? Are there any automated scripts for this?
- Are there any existing icon theme specifications (e.g., Freedesktop Icon Theme Specification) that gFTP currently adheres to or should aim to adhere to for its icon naming conventions?

---

## Change Triggers

- **Trigger:** Initial code investigation reveals a highly customized or non-standard icon loading mechanism in gFTP, deviating significantly from common GTK3 patterns.
    - **Expected response:** Pause, re-evaluate existing assumptions about GTK3 standard behavior, potentially re-scope to include reverse-engineering custom icon logic.
- **Trigger:** Attempts to convert `.xpm` icons result in unacceptable visual quality (e.g., jagged edges, poor scaling), and no readily available superior alternatives exist.
    - **Expected response:** Pause, escalate to design/product for decision on sourcing new icon assets or re-evaluating visual quality expectations.
- **Trigger:** Inability to configure Meson to correctly place icons for both macOS and Linux without resorting to brittle platform-specific hacks.
    - **Expected response:** Pause, explore alternative build system approaches for asset management, or consider more complex runtime loading solutions.

---

## Subtask Gate (MANDATORY — FINAL)

### Evaluation
- subtasks_likely: NO
- rationale: The task is focused on resolving a single, coherent problem (missing icons) through a combination of asset conversion, build system configuration, and targeted code adjustments. While there are open questions and potential risks, they appear manageable within the scope of a single development task without requiring independent, separately shippable sub-components. The problem domain is well-defined, and the expected solution path is relatively linear: investigate, convert, configure, verify.

Time Created: 2026-02-22 00:00:00  
Time Modified: 2026-02-22 00:00:00
