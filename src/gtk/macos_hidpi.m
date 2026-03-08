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
