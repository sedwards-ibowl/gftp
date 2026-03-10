# HiDPI (Retina) Support on macOS

gFTP now includes support for HiDPI (Retina) displays on macOS when built with the GTK3/GDK3 Quartz backend.

## Implementation Details

Support is implemented through a combination of programmatic detection and environment configuration:

1.  **Native Scale Detection**: A small Objective-C helper (`src/gtk/macos_hidpi.m`) uses the AppKit `backingScaleFactor` API to determine the display's scale factor (e.g., `2.0` for Retina displays).
2.  **GDK Configuration**: A new helper (`gftp_macos_init_environment()`) is invoked very early in the process.  The routine is marked with `__attribute__((constructor))` so that it runs even before `main()` when the bundle is opened by Finder.  It sets `GDK_BACKEND`, `PANGOCAIRO_BACKEND`, and calculates `GDK_SCALE`/`GDK_DPI_SCALE` from the detected backing scale factor.  If you already exported `GDK_SCALE` in a launcher script, that value will be respected because the helper uses `setenv(..., 0)`.
    - Note: GTK3 only supports integer scaling. A scale of `2.0` results in `GDK_SCALE=2`.
3.  **Backend Forcing**: The application explicitly sets `GDK_BACKEND=quartz` and `PANGOCAIRO_BACKEND=coretext` programmatically. This ensures the correct rendering paths are used and that HiDPI settings are respected even when not in debug mode.
4.  **Override Support**: The programmatic detection uses `setenv(..., 0)`, meaning if you manually export `GDK_SCALE` in your shell or launcher script, your manual value will take precedence.

### Why did GTK_DEBUG help?
`GTK_DEBUG=interactive` triggers GTK's interactive debugger, which creates a tiny offscreen window during startup.  that window initialization is what actually causes the Quartz backend to notice the retina scale factor.  our code now performs the same "priming" step explicitly by creating a short‑lived, hidden `GtkWindow` on the default screen; this is a more reliable and screen‑aware technique than the earlier raw `gdk_window_new` attempt, which could return `NULL` when no screen was set.  the debugger flag is therefore no longer necessary.
## Bundle Requirements

For HiDPI to work correctly within an `.app` bundle, macOS requires a specific key in the `Info.plist`. Without this key, macOS may render the application at a lower resolution and then upscale it, resulting in a blurry interface.

Ensure your `Contents/Info.plist` contains:

```xml
<key>NSHighResolutionCapable</key>
<true/>
```

If you are using `AppBundleGenerator`, you may need to manually add this key after the bundle is created if the generator does not yet support it natively.

## Troubleshooting

If the interface still appears blurry or incorrectly sized:

1.  **Verify the Backend**: Ensure you are using the Quartz backend (default for macOS builds).
2.  **Check Info.plist**: Right-click `gFTP.app` -> `Show Package Contents` -> `Contents/Info.plist` and verify the `NSHighResolutionCapable` key.
3.  **Manual Override**: Try running from the terminal with `GDK_SCALE=2 ./gftp-gtk` to see if the scaling changes.
4.  **Font Rendering**: Ensure `PANGOCAIRO_BACKEND=coretext` is set in your launcher script for the best text quality on HiDPI displays.
