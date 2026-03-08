#include "gftp.h"
#include <Foundation/Foundation.h>
#import <NetFS/NetFS.h>
#import <CoreFoundation/CoreFoundation.h>

/**
 * gftp_macos_protocol_smb_cifs_stub
 *
 * DIRECTION: Refined NetFS Native Bridge.
 * Using NetFSMountURLSync to hand off SMB complexity to the macOS kernel.
 */

/*
IMPLEMENTATION REFERENCE (User Provided):
-----------------------------------------
CFURLRef url = CFURLCreateWithString(NULL, CFSTR("smb://server/share"), NULL);

CFMutableDictionaryRef openOptions =
    CFDictionaryCreateMutable(NULL, 0,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);

CFDictionarySetValue(openOptions, kNetFSUserNameKey, CFSTR("user"));
CFDictionarySetValue(openOptions, kNetFSPasswordKey, CFSTR("pass"));

CFURLRef mountURL = NULL;

NetFSMountURLSync(
    url,
    NULL,
    NULL,
    NULL,
    openOptions,
    NULL,
    &mountURL);
-----------------------------------------
*/

/*
gFTP Protocol Mapping (Updated):
- CONNECT: Implement wrapper for NetFSMountURLSync. 
           Must handle credentials from gftp_request and return mount path.
- DISCONNECT: Unmount logic via NetFS or unistd.h (unmount).
- LIST/GET/PUT: Map to NSFileManager operations on the mount point.
*/

/**
 * gftp_macos_smb_connect
 * 
 * Performs a synchronous SMB mount using NetFSMountURLSync.
 * Returns 0 on success, or a negative error code on failure.
 */
int gftp_macos_smb_connect(const char *server_url, const char *username, const char *password, char **out_mount_path) {
    if (!server_url || !out_mount_path) return -1;

    CFStringRef urlStr = CFStringCreateWithCString(NULL, server_url, kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithString(NULL, urlStr, NULL);
    CFRelease(urlStr);

    if (!url) return -1;

    CFMutableDictionaryRef openOptions = CFDictionaryCreateMutable(NULL, 0,
                                                                  &kCFTypeDictionaryKeyCallBacks,
                                                                  &kCFTypeDictionaryValueCallBacks);

    if (username && *username) {
        CFStringRef userStr = CFStringCreateWithCString(NULL, username, kCFStringEncodingUTF8);
        CFDictionarySetValue(openOptions, kNetFSUserNameKey, userStr);
        CFRelease(userStr);
    }

    if (password && *password) {
        CFStringRef passStr = CFStringCreateWithCString(NULL, password, kCFStringEncodingUTF8);
        CFDictionarySetValue(openOptions, kNetFSPasswordKey, passStr);
        CFRelease(passStr);
    }

    // Set a soft mount to avoid permanent hangs if the server goes away
    CFDictionarySetValue(openOptions, kNetFSSoftMountKey, kCFBooleanTrue);

    CFURLRef mountURL = NULL;
    int result = NetFSMountURLSync(url,
                                   NULL, // mountpoint
                                   NULL, // user
                                   NULL, // group
                                   openOptions,
                                   NULL, // mountOptions
                                   (CFArrayRef *)&mountURL);

    CFRelease(url);
    CFRelease(openOptions);

    if (result == 0 && mountURL) {
        CFStringRef pathStr = CFURLCopyFileSystemPath(mountURL, kCFURLPOSIXPathStyle);
        if (pathStr) {
            const char *path = CFStringGetCStringPtr(pathStr, kCFStringEncodingUTF8);
            if (path) {
                *out_mount_path = strdup(path);
            } else {
                // Fallback if CFStringGetCStringPtr fails
                size_t len = CFStringGetMaximumSizeForEncoding(CFStringGetLength(pathStr), kCFStringEncodingUTF8) + 1;
                *out_mount_path = malloc(len);
                CFStringGetCString(pathStr, *out_mount_path, len, kCFStringEncodingUTF8);
            }
            CFRelease(pathStr);
        }
        CFRelease(mountURL);
        return 0;
    }

    if (mountURL) CFRelease(mountURL);
    return result != 0 ? -result : -1;
}

static gftp_config_vars config_vars[] = 
{
  {"", "SMB/CIFS", gftp_option_type_notebook, NULL, NULL, 
   GFTP_CVARS_FLAGS_SHOW_BOOKMARK, NULL, GFTP_PORT_GTK, NULL},
  {NULL, NULL, 0, NULL, NULL, 0, NULL, 0, NULL}
};

void smb_register_module (void)
{
    gftp_register_config_vars (config_vars);
}

static void smb_request_destroy (gftp_request * request)
{
    (void)request;
    // Cleanup mount if needed
}

static int smb_chdir (gftp_request * request, const char *directory)
{
    if (request->directory) g_free (request->directory);
    request->directory = g_strdup (directory);
    return 0;
}

int smb_init (gftp_request * request)
{
    g_return_val_if_fail (request != NULL, GFTP_EFATAL);

    request->protonum = GFTP_PROTOCOL_WINDOWS;
    request->url_prefix = "smb";

    request->init = smb_init;
    request->destroy = smb_request_destroy;
    request->read_function = gftp_fd_read;
    request->write_function = gftp_fd_write;
    
    // Core protocol mapping (Stubs for now)
    request->connect = NULL; 
    request->disconnect = NULL;
    request->chdir = smb_chdir;
    request->list_files = NULL;
    request->get_file = NULL;
    request->put_file = NULL;
    
    request->need_hostport = 1;
    request->need_username = 1;
    request->need_password = 1;
    request->use_cache = 1;

    return 0;
}
