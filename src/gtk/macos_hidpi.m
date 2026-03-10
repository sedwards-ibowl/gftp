#import <AppKit/AppKit.h>

/**
 * gftp_macos_get_backing_scale_factor:
 *
 * This function returns the backing scale factor of the main screen.
 * For standard displays, this is 1.0. For Retina/HiDPI displays,
 * this is typically 2.0.
 */
float gftp_macos_get_backing_scale_factor(void) {
    /* We don't need a full NSApplication init just to query the screen's scale factor. */
    @autoreleasepool {
        NSScreen *mainScreen = [NSScreen mainScreen];
        if (mainScreen != nil) {
            return (float)[mainScreen backingScaleFactor];
        }
    }
    return 1.0f;
}


/*
 * gftp_macos_init_environment:
 *
 *  Called very early in `main()` (or via constructor) to configure the
 *  GTK/GDK environment on macOS.  The routine sets the Quartz backend
 *  and adjusts the `GDK_SCALE`/`GDK_DPI_SCALE` variables based on the
 *  display's backing scale factor.  Passing `overwrite = 0` allows a
 *  user-installed value (for example from a launcher script) to take
 *  precedence.
 *
 *  Historically we kludged this by exporting GTK_DEBUG=interactive, which
 *  ended up creating a hidden debug window and thus forcing GDK to realize
 *  the proper scale factor.  By explicitly setting the environment here we
 *  can eliminate that magic bullet and launch HiDPI correctly from the
 *  bundle or command line.
 */
void gftp_macos_init_environment(void) {
    float scale = gftp_macos_get_backing_scale_factor();

    /* backend and rendering choices */
    setenv("GDK_BACKEND", "quartz", 0);
    setenv("PANGOCAIRO_BACKEND", "coretext", 0);

    if (scale > 1.0f) {
        char buf[16];
        /* GTK3 only understands integer scaling factors */
        snprintf(buf, sizeof(buf), "%.0f", scale);
        setenv("GDK_SCALE", buf, 0);
        setenv("GDK_DPI_SCALE", "1.0", 0);
    }
}
