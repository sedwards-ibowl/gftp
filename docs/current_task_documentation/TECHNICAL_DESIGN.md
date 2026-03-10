# Technical Design: GTK2 Removal and HiDPI Modernization

## 1. Architectural Strategy
The project will move to a **GTK3-Only** architecture. This simplifies the codebase by removing the need for `gtkcompat.h` macros that map to GTK2. We will leverage native GTK3 features for HiDPI, layout, and event handling.

## 2. Build System Changes
- **`meson_options.txt`**:
    - Remove `gtk2` and `gtk3` boolean options.
    - Keep `gtkport` as a boolean to enable/disable the GTK UI entirely.
- **`meson.build`**:
    - Default `gtk_dep` will search for `gtk+-3.0`.
    - Fail build if `gtkport` is enabled but GTK3 is not found.
    - Consolidate macOS-specific dependencies (`gtk-mac-integration-gtk3`).

## 3. Structural Cleanup
- **`src/gtkcompat.h`**:
    - Prune all `#if GTK_MAJOR_VERSION == 2` blocks.
    - Convert remaining macros into inline functions where appropriate, or remove them and use native GTK3 calls in the source files.
- **`src/gtk/transfer.c`**:
    - Remove the `TRANSFER_GTK_TREEVIEW` guard.
    - Delete the `GtkCTree`/`GtkCList` implementation of the transfer list.
    - Promote the `GtkTreeView` implementation as the sole implementation.
- **Widget Migration**:
    - Convert `GtkTable` to `GtkGrid`.
    - Convert `GtkVBox`/`GtkHBox` to `GtkBox` with `GTK_ORIENTATION_VERTICAL/HORIZONTAL`.

## 4. macOS HiDPI Initialization
- **`src/gtk/macos_hidpi.m`**:
    - Expand `gftp_macos_get_backing_scale_factor()` to be more robust.
    - Add `gftp_macos_init_environment()` to set `GDK_SCALE` and `GDK_DPI_SCALE` based on the detected factor.
- **`src/gtk/gftp-gtk.c` (main)**:
    - Call `gftp_macos_init_environment()` before `gtk_init`.
    - Remove `setenv("GTK_DEBUG", "interactive", 1)`.

## 5. Asset Management
- **Icon Loader**:
    - Update `gftp_get_pixbuf` in `src/gtk/misc-gtk.c` to check for SVG versions of icons first.
    - If a PNG is used, load the 2x version (if available) or scale up the base version using `gdk_pixbuf_get_from_surface` for Retina clarity.

## 6. CSS Aesthetic Engine
- **`src/gtk/gftp-gtk.css`**:
    - Implement a base CSS file to enforce the "Midnight Commander" look (e.g., specific row heights, background colors for directory/executable types).
    - Use CSS selectors to target the new `GtkTreeView` elements.
