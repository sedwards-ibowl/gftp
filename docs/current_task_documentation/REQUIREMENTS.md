# Requirements: GTK2 Removal and HiDPI Modernization

## 1. Build System Modernization
- **R1.1**: Remove `gtk2` and `gtk3` boolean options from `meson_options.txt`.
- **R1.2**: Implement a single `gtkport` option (or similar) that defaults to GTK3.
- **R1.3**: Update `meson.build` to enforce GTK3 as the minimum requirement for the GTK port.
- **R1.4**: Bump minimum GLib requirement to a modern stable version (e.g., 2.50+) to simplify compatibility.

## 2. Legacy Code Removal (The "Purge")
- **R2.1**: Delete all code blocks wrapped in `#if GTK_MAJOR_VERSION == 2`.
- **R2.2**: Delete all code blocks wrapped in `#if !defined(TRANSFER_GTK_TREEVIEW)`.
- **R2.3**: Remove `src/gtkcompat.h` macros that map to GTK2 functions (e.g., `gtk_hbox_new`).
- **R2.4**: Replace remaining legacy widget usage (`GtkTable`, `GtkVBox`, `GtkHBox`) with modern GTK3 equivalents (`GtkGrid`, `GtkBox`).

## 3. HiDPI Implementation (The "Correct Fix")
- **R3.1**: Eliminate the `GTK_DEBUG=interactive` hack in `main()`.
- **R3.2**: Implement robust macOS scale factor detection using `NSScreen` in an early-init phase.
- **R3.3**: Ensure `GDK_SCALE` and `GDK_DPI_SCALE` are set correctly based on detected resolution before `gtk_init`.
- **R3.4**: Implement a "High-Res Pixmap" loader that selects the best available asset (PNG or SVG) for the current scale factor.

## 4. UI Consistency
- **R4.1**: Maintain the "Midnight Commander" dual-pane aesthetic using CSS for spacing and borders.
- **R4.2**: Use `GtkPaned` for the main window split to resolve the "middle column grab" bug on macOS.
- **R4.3**: Restore missing "Arrow" icons on macOS using symbolic icons or properly scaled pixbufs.

## 5. Portability
- **R5.1**: Ensure the modernized code compiles and runs on both macOS (Quartz) and Linux (X11/Wayland).
- **R5.2**: Use platform-agnostic GTK3 APIs wherever possible, isolating macOS-specific logic to `macos_hidpi.m` or similar.
