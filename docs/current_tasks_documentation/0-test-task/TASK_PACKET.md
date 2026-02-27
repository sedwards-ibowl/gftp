# TASK_PACKET.md

## 1. Objective

To resolve the issue of missing icons for files, folders, and binaries in the gFTP application on macOS and Linux by migrating from unsupported `.xpm` icon formats to compatible `.png` and `.svg` formats. This includes converting existing assets, updating code references, and ensuring correct integration into the Meson build system and macOS application bundle.

## 2. Non-goals

- Creating entirely new icon designs or aesthetic overhauls, unless strictly necessary due to inability to convert an existing `.xpm` icon.
- Refactoring unrelated parts of the codebase.
- Changing application functionality beyond icon display.

## 3. Constraints

- **Platform Compatibility:** Solution must work for both macOS and Linux environments.
- **GTK3 Compatibility:** All icon assets must be compatible with GTK3.
- **Build System:** The Meson build system must be correctly configured to handle new icon formats and exclude old ones.
- **Tooling:** Conversion of `.xpm` to `.png` and `.svg` should leverage existing command-line tools like `sips` (macOS) or `ImageMagick` (`convert`).
- **macOS App Bundle:** The new icons must be correctly packaged and discoverable within the `gFTP.app` bundle, integrating with existing scripts (e.g., `create_app_bundle.sh`, `build_gftp_app.sh`, `AppBundleGenerator`).

## 4. Exact file touch list

**Create:**
- `icons/<size>/actions/*.png` (e.g., `icons/16x16/actions/dir.png`, `icons/22x22/actions/dir.png`, etc. for all relevant sizes)
- `icons/scalable/actions/*.svg` (for scalable icons, if conversion is feasible)

**Modify:**
- `src/gtk/menu-items.c`
- `src/gtk/misc-gtk.c`
- `src/gtk/transfer.c`
- `src/gtk/bookmarks.c`
- `lib/config_file.c`
- `build_gftp_homebrew.sh`
- `docs/sample.gftp/gftprc`
- `meson.build` (root)
- `icons/meson.build`
- `po/gftp.pot` (and relevant `.po` files if "XPM file" string is updated)
- `README.md` (if icon references are present and need updating)
- `CLAUDE.md` (if icon references are present and need updating)

**Do NOT touch:**
- Any files outside the `src/`, `lib/`, `icons/`, `po/`, `docs/`, `build_gftp_homebrew.sh`, `meson.build` context, unless specifically identified as necessary during the implementation phase and approved.

## 5. Step-by-step implementation checklist

**Phase 1: Icon Asset Preparation**
- [x] **1.1 Identify Unique XPMs:** Compile a definitive list of all unique `.xpm` icon files that need conversion, focusing on `icons/legacy/` and `docs/sample.gftp/`.
- [x] **1.2 Convert to PNG:** For each identified `.xpm` icon, convert it to high-quality `.png` format in various sizes (e.g., 16x16, 22x22, 24x24, 32x32, 48x48).
    - [x] Utilize `sips` (on macOS) or `ImageMagick` (`convert`) for batch conversion, or any other tool that will  work.
    - [x] Place converted `.png` files into appropriate size-specific directories (e.g., `icons/16x16/actions/`, `icons/22x22/actions/`, etc.).
- [x] **1.3 Convert to SVG (if feasible):** For any `.xpm` icons that can be losslessly converted to scalable vector graphics, generate `.svg` versions and place them in `icons/scalable/actions/`. If direct `.xpm` to `.svg` is not viable, consider creating `.svg` from high-resolution `.png`s or sourcing new vector assets.
- [ ] **1.4 Remove Legacy XPMs:** Delete the original `.xpm` files from `icons/legacy/` and `docs/sample.gftp/`, and ensure they are no longer installed by the build system.

**Phase 2: Codebase Adaptation**
- [x] **2.1 Update `gftp_get_pixbuf`:** Modify `src/gtk/misc-gtk.c`'s `gftp_get_pixbuf` function (and potentially `open_xpm`) to prioritize loading icons from the GTK icon theme, then fallback to direct file loading of `.png` or `.svg` files from standard icon paths. Remove explicit `.xpm` loading logic.
- [x] **2.2 Update Hardcoded Icon References:** Review and update `src/gtk/menu-items.c`, `src/gtk/transfer.c`, and `src/gtk/bookmarks.c` to remove direct references to `.xpm` filenames. Instead, they should request icons by name (e.g., "dir", "open_dir", "gftp-logo") allowing GTK's icon theme to resolve the appropriate `.png` or `.svg` asset.
- [x] **2.3 Update `lib/config_file.c`:** Remove or update any strings referring to "XPM file" in `lib/config_file.c` and associated `po/*.po` translation files if the `.xpm` format is no longer supported for icon definition.
- [x] **2.4 Update `gftprc` Mappings:** Modify `docs/sample.gftp/gftprc` (and any installed `gftprc` versions) to map file extensions directly to the new `.png` icon names (e.g., `ext=.rpm:rpm.png:B:`). Ensure that build scripts apply these changes.

**Phase 3: Build System Integration**
- [x] **3.1 Modify `meson.build` files:**
    - [x] Update `icons/meson.build` to include the newly created `.png` and `.svg` files in the installation targets for various sizes.
    - [x] Ensure that `meson.build` files no longer reference or install the `.xpm` files.
- [x] **3.2 Update Build Scripts:**
    - [x] Review `build_gftp_homebrew.sh` (and potentially `create_app_bundle.sh`, `build_gftp_app.sh`).
    - [x] Remove the XPM to PNG conversion logic from `build_gftp_homebrew.sh` as this will now be handled during asset preparation.
    - [x] **Crucially, remove any steps that copy `.xpm` files into the macOS app bundle (`$BUNDLE_PATH/Contents/Resources/share/gftp/`).**
    - [x] Ensure the scripts correctly package the new `.png` and `.svg` icons into the `gFTP.app` bundle in the appropriate locations for GTK to discover them.

**Phase 4: Verification and Cleanup**
- [ ] **4.1 Full Build:** Perform a clean build of gFTP for both macOS and Linux.
- [x] **4.2 XPM Absence Check:** Verify that no `.xpm` files are present in the installed directories or within the `gFTP.app` bundle on macOS.
- [ ] **4.3 Visual Verification:** Launch the gFTP GTK interface on both macOS and Linux.
    - [ ] Navigate through local and remote file systems.
    - [x] Confirm that all expected file, folder, and binary icons are correctly displayed and are not missing.
    - [ ] Verify that the gFTP application logo is displayed correctly.
- [ ] **4.4 Logging/Error Check:** Monitor console output for any warnings or errors related to icon loading.

## 6. Acceptance tests

**Build and Run (macOS):**
1.  `./build_gftp_homebrew.sh` (or equivalent macOS build script)
2.  `open gFTP.app`
3.  **Expected Outcome:**
    - The gFTP application launches successfully.
    - All file and folder icons in both local and remote panes are visible and correctly rendered (no missing icons).
    - The application's logo is displayed correctly.

**Build and Run (Linux - Example, adapt to actual setup):**
1.  `meson setup build`
2.  `meson compile -C build`
3.  `meson install -C build` (or `sudo meson install -C build`)
4.  `/usr/local/bin/gftp-gtk` (or equivalent installed binary path)
5.  **Expected Outcome:**
    - The gFTP application launches successfully.
    - All file and folder icons in both local and remote panes are visible and correctly rendered.

**File System Check (macOS):**
1.  `find gFTP.app -name "*.xpm"`
2.  **Expected Outcome:** Command should return no results (no `.xpm` files within the app bundle).
3.  `find gFTP.app -name "*.png"`
4.  **Expected Outcome:** Should list many `.png` files, including those corresponding to the converted `.xpm` icons.

**Code References Check:**
1.  `grep -r ".xpm" src/ lib/ --exclude-dir=po` (excluding translation files)
2.  **Expected Outcome:** Should return minimal or no results, indicating that direct `.xpm` references have been removed from the C code.

## 7. Open risks / blockers

- **Icon Conversion Quality:** The primary risk is that the conversion from older `.xpm` files to `.png` or `.svg` might result in poor visual quality (e.g., pixelation, blurriness) on modern high-resolution displays. This could necessitate manual cleanup or redesign of certain icons.
- **GTK Icon Theme Integration:** Ensuring the new icons are correctly integrated into the GTK icon theme mechanism, and that the application successfully discovers and uses them, might require careful debugging.
- **Build Script Complexity:** The existing build scripts, particularly for macOS bundling, can be complex. Modifying them to correctly handle new icon paths and formats while removing old `.xpm` dependencies without introducing regressions is a potential blocker.
- **Comprehensive XPM Reference Removal:** Despite searches, there might be obscure `.xpm` references in the codebase or configuration files that are missed, leading to residual issues.
- **SVG Generation:** Direct `.xpm` to `.svg` conversion might not yield high-quality results. If scalable vector graphics are truly required, new `.svg` assets might need to be created from scratch or from high-resolution `.png` sources.
