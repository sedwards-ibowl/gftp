# Discovery: GTK2 Removal and HiDPI Modernization

## Current State

### Build System
- `meson_options.txt` contains options for both `gtk2` and `gtk3`.
- `meson.build` has separate dependency checks and logic for both versions.
- Default build currently targets GTK2 (`value : true` in `meson_options.txt`).

### Compatibility Layer
- `src/gtkcompat.h` is a significant body of code (approx. 400 lines) dedicated to bridging GTK2 and GTK3.
- It contains macros that map modern GTK3 functions (like `gtk_box_new`) back to legacy GTK2 counterparts (like `gtk_hbox_new`).
- It also handles GLib version checks back to 2.18.

### UI Implementation
- **Transfer Window (`src/gtk/transfer.c`)**: Contains two complete implementations of the transfer list: one using modern `GtkTreeView` (active when `TRANSFER_GTK_TREEVIEW` is defined) and one using legacy `GtkCTree`/`GtkCList`.
- **Main Panes (`src/gtk/listbox.c`)**: Already use `GtkTreeView`, but maintain some compatibility baggage.
- **Initialization (`src/gtk/gftp-gtk.c`)**: Currently uses a "Magic Bullet" hack (`GTK_DEBUG=interactive`) to force HiDPI initialization on macOS, as standard initialization fails to acknowledge the scale factor correctly.

## Targets for Removal

### Files
- `src/gtk/macos_hidpi.m` (To be refactored/expanded)
- `src/gtkcompat.h` (To be significantly pruned or eliminated)

### Macros and Defines
- `TRANSFER_GTK_TREEVIEW`: No longer needed; will be the only path.
- `GTK_MAJOR_VERSION == 2` blocks in:
    - `src/gtk/gftp-gtk.c`
    - `src/gtk/gftp-gtk.h`
    - `src/gtkcompat.h`
- `GTK_CHECK_VERSION(3,0,0)`: Most can be removed as we will assume GTK 3+.

### Legacy Code
- `GtkCList` and `GtkCTree` usage in `src/gtk/transfer.c` and `src/gtk/gtkui_transfer.c`.
- `GtkTable`, `GtkVBox`, `GtkHBox`, `GtkArrow`, `GtkHandleBox`, `GtkCombo` (if any remain) to be replaced by `GtkGrid`, `GtkBox`, `GtkImage`, `GtkPaned`, `GtkComboBox`.

## HiDPI Targets
- **macOS Initialization**: Move scale factor detection to an Objective-C bridge called before `gtk_init`.
- **Environment Cleanup**: Eliminate the need for `GDK_SCALE` and `GTK_DEBUG` environment variables in the startup process.
- **Icon Resolution**: Implement a hybrid PNG/SVG loader that respects the system scale factor.
