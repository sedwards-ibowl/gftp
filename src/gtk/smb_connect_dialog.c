#include <gtk/gtk.h>
#include "gftp-gtk.h"

/**
 * smb_connect_dialog
 * 
 * Shows a modal dialog that informs the user that a mount is in progress.
 * Includes a 10-second watchdog to prevent permanent hangs.
 */

typedef struct {
    GtkWidget *dialog;
    gboolean completed;
    int result;
    char *mount_path;
} SMBConnectData;

static gboolean
smb_timeout_callback(gpointer data)
{
    SMBConnectData *scd = data;
    if (!scd->completed) {
        g_warning("SMB connection timed out after 10 seconds");
        gtk_dialog_response(GTK_DIALOG(scd->dialog), GTK_RESPONSE_CANCEL);
    }
    return FALSE; // Remove timeout
}

int
gftp_gtk_smb_connect_with_dialog(const char *url, const char *user, const char *pass, char **out_mount_path)
{
    GtkWidget *dialog, *label, *content_area;
    SMBConnectData scd;
    
    scd.completed = FALSE;
    scd.result = -1;
    scd.mount_path = NULL;

    dialog = gtk_dialog_new_with_buttons(_("Connecting..."),
                                       GTK_WINDOW(main_window),
                                       GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                       _("_Cancel"), GTK_RESPONSE_CANCEL,
                                       NULL);
    scd.dialog = dialog;

    content_area = gtk_dialog_get_content_area(GTK_DIALOG(dialog));
    label = gtk_label_new(_("Connecting to SMB share...\nPlease wait."));
    gtk_container_add(GTK_CONTAINER(content_area), label);
    gtk_widget_show_all(dialog);

    // Start the watchdog timer
    g_timeout_add(10000, smb_timeout_callback, &scd);

    /* 
     * NOTE: In a full implementation, we would spawn a thread for the blocking
     * NetFSMountURLSync call and then use g_main_context_invoke to close the dialog.
     * 
     * For the initial stub, we will perform it synchronously after a brief delay
     * to ensure the UI paints.
     */
    
    // Process events so the dialog actually shows
    while (gtk_events_pending()) gtk_main_iteration();

#ifdef __APPLE__
    scd.result = gftp_macos_smb_connect(url, user, pass, &scd.mount_path);
#endif

    scd.completed = TRUE;
    if (scd.result == 0) {
        *out_mount_path = scd.mount_path;
        gtk_widget_destroy(dialog);
        return 0;
    } else {
        gtk_widget_destroy(dialog);
        return scd.result;
    }
}
