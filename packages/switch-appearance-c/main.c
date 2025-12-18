#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <time.h>

#ifdef __APPLE__
#define IS_MACOS 1
#else
#define IS_MACOS 0
#endif

static int is_macos(void) {
    return IS_MACOS;
}

static int is_kde(void) {
    const char *desktop = getenv("XDG_CURRENT_DESKTOP");
    if (desktop) {
        if (strstr(desktop, "KDE") || strstr(desktop, "Plasma")) {
            return 1;
        }
    }

    // Fallback: check if plasmashell is running
    return system("pgrep plasmashell >/dev/null 2>&1") == 0;
}

static int run_command(const char *cmd) {
    return system(cmd);
}

static char *run_command_output(const char *cmd) {
    FILE *fp = popen(cmd, "r");
    if (!fp) return NULL;

    static char buffer[4096];
    size_t len = fread(buffer, 1, sizeof(buffer) - 1, fp);
    buffer[len] = '\0';
    pclose(fp);

    // Trim trailing whitespace
    while (len > 0 && (buffer[len-1] == '\n' || buffer[len-1] == '\r' || buffer[len-1] == ' ')) {
        buffer[--len] = '\0';
    }

    return buffer;
}

// macOS Functions

static int get_current_theme_macos(void) {
    char *output = run_command_output(
        "osascript -e 'tell application \"System Events\" to tell appearance preferences to get dark mode'"
    );
    return output && strcmp(output, "true") == 0;
}

static int set_dark_mode_macos(int dark) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd),
        "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to %s'",
        dark ? "true" : "false"
    );
    return run_command(cmd);
}

static int set_wallpaper_macos(const char *color) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
        "osascript -e '\n"
        "tell application \"System Events\"\n"
        "    tell every desktop\n"
        "        set picture to \"/System/Library/Desktop Pictures/Solid Colors/%s.png\"\n"
        "    end tell\n"
        "end tell\n"
        "'",
        color
    );
    return run_command(cmd);
}

static int open_settings_macos(void) {
    return run_command(
        "osascript -e '\n"
        "tell application \"System Settings\"\n"
        "    activate\n"
        "    delay 0.5\n"
        "    tell application \"System Events\"\n"
        "        tell process \"System Settings\"\n"
        "            click menu item \"Wallpaper\" of menu \"View\" of menu bar 1\n"
        "        end tell\n"
        "    end tell\n"
        "end tell\n"
        "' >/dev/null 2>&1"
    );
}

// KDE Plasma Functions

static int get_current_theme_kde(void) {
    char *output = run_command_output("plasma-apply-colorscheme --list-schemes 2>/dev/null");
    if (!output) return 0;

    char *line = strtok(output, "\n");
    while (line) {
        if (strstr(line, "(current color scheme)")) {
            return strstr(line, "Dark") != NULL;
        }
        line = strtok(NULL, "\n");
    }
    return 0;
}

static int set_theme_kde(int dark) {
    char cmd[128];
    snprintf(cmd, sizeof(cmd), "plasma-apply-colorscheme %s",
        dark ? "BreezeDark" : "BreezeLight"
    );
    return run_command(cmd);
}

static int set_wallpaper_kde(const char *color) {
    const char *rgb = strcmp(color, "Black") == 0 ? "0,0,0" : "192,192,192";

    // Get all desktop IDs
    char *output = run_command_output(
        "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \"\n"
        "var allDesktops = desktops();\n"
        "var output = [];\n"
        "for (var i = 0; i < allDesktops.length; i++) {\n"
        "    var d = allDesktops[i];\n"
        "    output.push(d.id);\n"
        "}\n"
        "output.join(',');\n"
        "\" 2>/dev/null"
    );

    if (!output || strlen(output) == 0) return -1;

    char *screen = strtok(output, ",");
    while (screen) {
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
            "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \"\n"
            "var d = desktopById(%s);\n"
            "d.wallpaperPlugin = 'org.kde.color';\n"
            "d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];\n"
            "d.writeConfig('Color', '%s');\n"
            "\" >/dev/null 2>&1",
            screen, rgb
        );
        run_command(cmd);
        screen = strtok(NULL, ",");
    }
    return 0;
}

static int open_settings_kde(void) {
    return run_command("systemsettings appearance >/dev/null 2>&1 &");
}

// State management

static void get_state_dir(char *buf, size_t size) {
    const char *home = getenv("HOME");
    if (!home) home = "/tmp";
    snprintf(buf, size, "%s/.local/state/switch-appearance", home);
}

static void get_state_file(char *buf, size_t size) {
    char dir[512];
    get_state_dir(dir, sizeof(dir));
    snprintf(buf, size, "%s/last-run", dir);
}

static int write_state(void) {
    char dir[512];
    get_state_dir(dir, sizeof(dir));

    // Create directory
    char cmd[600];
    snprintf(cmd, sizeof(cmd), "mkdir -p '%s'", dir);
    run_command(cmd);

    char file[512];
    get_state_file(file, sizeof(file));

    // Get today's date
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);
    char date[16];
    strftime(date, sizeof(date), "%Y-%m-%d", tm);

    FILE *fp = fopen(file, "w");
    if (!fp) return -1;
    fprintf(fp, "%s", date);
    fclose(fp);
    return 0;
}

static void remove_state(void) {
    char file[512];
    get_state_file(file, sizeof(file));
    unlink(file);
}

// Platform-agnostic helpers

static int set_dark_mode(int dark) {
    const char *color = dark ? "Black" : "Silver";

    if (is_macos()) {
        if (set_dark_mode_macos(dark) != 0) return -1;
        return set_wallpaper_macos(color);
    } else if (is_kde()) {
        if (set_theme_kde(dark) != 0) return -1;
        return set_wallpaper_kde(color);
    }
    return -1;
}

static int get_current_theme(void) {
    if (is_macos()) {
        return get_current_theme_macos();
    } else if (is_kde()) {
        return get_current_theme_kde();
    }
    return -1;
}

static void open_settings(void) {
    if (is_macos()) {
        open_settings_macos();
    } else if (is_kde()) {
        open_settings_kde();
    }
}

static int handle_init(void) {
    if (!is_macos() && !is_kde()) {
        fprintf(stderr, "Unsupported platform\n");
        return 1;
    }

    if (set_dark_mode(1) != 0) {
        fprintf(stderr, "Failed to set dark mode\n");
        return 1;
    }

    printf("Set dark mode and wallpaper (init)\n");
    remove_state();
    return 0;
}

static int handle_toggle(void) {
    if (!is_macos() && !is_kde()) {
        fprintf(stderr, "Unsupported platform or desktop environment\n");
        return 1;
    }

    int is_dark = get_current_theme();
    int new_dark = !is_dark;

    if (set_dark_mode(new_dark) != 0) {
        fprintf(stderr, "Failed to set appearance\n");
        return 1;
    }

    if (new_dark) {
        printf("Switched to Dark appearance\n");
    } else {
        printf("Switched to Light appearance\n");
    }

    if (write_state() != 0) {
        fprintf(stderr, "Warning: could not write state\n");
    }

    open_settings();
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc > 1 && strcmp(argv[1], "init") == 0) {
        return handle_init();
    }
    return handle_toggle();
}
