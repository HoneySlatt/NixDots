#define _GNU_SOURCE
#include <dlfcn.h>
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

static gboolean under_niri(void) {
    const char *socket = g_getenv("NIRI_SOCKET");
    const char *desktop = g_getenv("XDG_CURRENT_DESKTOP");
    return (socket && *socket) || (desktop && g_ascii_strcasecmp(desktop, "niri") == 0);
}

void gtk_window_set_decorated(GtkWindow *window, gboolean decorated) {
    static void (*original)(GtkWindow *, gboolean);
    if (!original) original = dlsym(RTLD_NEXT, "gtk_window_set_decorated");
    original(window, under_niri() ? FALSE : decorated);
}

void gtk_window_set_titlebar(GtkWindow *window, GtkWidget *titlebar) {
    static void (*original)(GtkWindow *, GtkWidget *);
    if (!original) original = dlsym(RTLD_NEXT, "gtk_window_set_titlebar");
    original(window, under_niri() ? NULL : titlebar);
}

static void apply_theme(WebKitWebView *view) {
    const char *path = g_object_get_data(G_OBJECT(view), "rqbit-theme-path");
    gchar *css = NULL;
    gsize length;
    if (!g_file_get_contents(path, &css, &length, NULL)) return;

    // Base64 keeps arbitrary CSS out of JavaScript string syntax.
    gchar *encoded = g_base64_encode((const guchar *)css, length);
    gchar *script = g_strdup_printf(
        "(() => { let s = document.getElementById('rqbit-quickshell-theme');"
        "if (!s) { s = document.createElement('style');"
        "s.id = 'rqbit-quickshell-theme'; document.head.appendChild(s); }"
        "s.textContent = new TextDecoder().decode(Uint8Array.from(atob('%s'),"
        "c => c.charCodeAt(0))); })()", encoded);
    webkit_web_view_evaluate_javascript(view, script, -1, NULL, NULL, NULL, NULL, NULL);
    g_free(script);
    g_free(encoded);
    g_free(css);
}

static void loaded(WebKitWebView *view, WebKitLoadEvent event, gpointer data) {
    (void)data;
    if (event == WEBKIT_LOAD_FINISHED) apply_theme(view);
}

static void changed(GFileMonitor *monitor, GFile *file, GFile *other,
                    GFileMonitorEvent event, WebKitWebView *view) {
    (void)monitor;
    (void)other;
    (void)event;
    gchar *name = g_file_get_basename(file);
    if (g_strcmp0(name, "quickshell.css") == 0) apply_theme(view);
    g_free(name);
}

WebKitUserContentManager *webkit_web_view_get_user_content_manager(WebKitWebView *view) {
    static WebKitUserContentManager *(*original)(WebKitWebView *);
    if (!original) original = dlsym(RTLD_NEXT, "webkit_web_view_get_user_content_manager");
    WebKitUserContentManager *manager = original(view);
    if (g_object_get_data(G_OBJECT(view), "rqbit-theme-path")) return manager;

    gchar *dir = g_build_filename(g_get_user_config_dir(), "rqbit-desktop", NULL);
    g_mkdir_with_parents(dir, 0700);
    gchar *path = g_build_filename(dir, "quickshell.css", NULL);
    g_object_set_data_full(G_OBJECT(view), "rqbit-theme-path", path, g_free);
    g_signal_connect(view, "load-changed", G_CALLBACK(loaded), NULL);

    // Watch the directory because switch-theme replaces the CSS atomically.
    GFile *directory = g_file_new_for_path(dir);
    GFileMonitor *monitor = g_file_monitor_directory(directory, G_FILE_MONITOR_NONE, NULL, NULL);
    if (monitor) {
        g_signal_connect_object(monitor, "changed", G_CALLBACK(changed), view, 0);
        g_object_set_data_full(G_OBJECT(view), "rqbit-theme-monitor", monitor, g_object_unref);
    }
    g_object_unref(directory);
    g_free(dir);
    return manager;
}
