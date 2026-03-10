# Risks and Assumptions: GTK2 Removal and HiDPI Modernization

## Risks
- **R1: Linux Regressions**: Removing GTK2 compatibility might inadvertently break the build on older Linux distributions that still rely on GTK2. *Mitigation: Standardize on GTK3+ and clearly document the dependency change in README.*
- **R2: Layout Breaks**: Converting `GtkTable` to `GtkGrid` or `GtkVBox` to `GtkBox` may cause subtle layout shifts that disrupt the "Midnight Commander" aesthetic. *Mitigation: Rigorous visual testing on both macOS and Linux during implementation.*
- **R3: CSS Theme Interference**: Custom CSS might conflict with the user's system theme. *Mitigation: Use specific CSS class names for gFTP widgets to avoid global selector collisions.*
- **R4: Initialization Race Conditions**: Detecting the scale factor via `NSScreen` before `gtk_init` might still fail if GDK hasn't fully loaded its Quartz backend. *Mitigation: Perform detection as early as possible and validate with a fallback to `GDK_SCALE=2` if needed.*

## Assumptions
- **A1**: All users of the GTK port are capable of installing GTK 3.0 or higher.
- **A2**: The "Magic Bullet" hack (`GTK_DEBUG=interactive`) was indeed covering up an initialization gap that can be resolved by correctly setting `GDK_SCALE`.
- **A3**: The performance benefits of using modern `GtkTreeView` and `GtkGrid` will outweigh the effort of the migration.
- **A4**: The project is committed to dropping GTK2 support to reduce technical debt.
