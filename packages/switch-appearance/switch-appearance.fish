#!/usr/bin/env fish

# Detect platform
function is_macos
    test (uname) = "Darwin"
end

function is_kde
    # Check environment variables first
    if test -n "$XDG_CURRENT_DESKTOP"
        if string match -q "*KDE*" "$XDG_CURRENT_DESKTOP"
            return 0
        else if string match -q "*Plasma*" "$XDG_CURRENT_DESKTOP"
            return 0
        end
    end

    # Fallback: check if plasmashell is running
    pgrep plasmashell >/dev/null 2>&1
end

# macOS Functions
function get_current_theme_macos
    osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode'
end

function set_wallpaper_macos
    set color $argv[1]
    set file_path "/System/Library/Desktop Pictures/Solid Colors/$color.png"

    osascript -e '
    tell application "System Events"
        tell every desktop
            set picture to "'$file_path'"
        end tell
    end tell
    '
end

function open_settings_macos
    osascript -e '
    tell application "System Settings"
        activate
        delay 0.5
        tell application "System Events"
            tell process "System Settings"
                click menu item "Wallpaper" of menu "View" of menu bar 1
            end tell
        end tell
    end tell
    ' 1>/dev/null
end

# KDE Plasma Functions
function get_current_theme_kde
    set scheme_output (plasma-apply-colorscheme --list-schemes 2>/dev/null | grep "(current color scheme)")
    if string match -q "*Dark*" "$scheme_output"
        echo "true"
    else
        echo "false"
    end
end

function set_theme_kde
    set mode $argv[1]
    if test "$mode" = "dark"
        plasma-apply-colorscheme BreezeDark
    else
        plasma-apply-colorscheme BreezeLight
    end
end

function set_wallpaper_kde
    set color $argv[1]

    # Use solid color wallpaper plugin
    if test "$color" = "Black"
        set rgb "0,0,0"
    else
        set rgb "192,192,192"  # Silver
    end

    # Set wallpaper for all screens
    for screen in (qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        var output = [];
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            output.push(d.id);
        }
        output.join(',');
    " 2>/dev/null | string split ',')
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var d = desktopById($screen);
            d.wallpaperPlugin = 'org.kde.color';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];
            d.writeConfig('Color', '$rgb');
        " >/dev/null 2>&1
    end
end

function open_settings_kde
    systemsettings appearance &
end

# State file to track manual appearance changes
set state_dir "$HOME/.local/state/switch-appearance"
set state_file "$state_dir/last-run"

function write_state
    mkdir -p $state_dir
    date "+%Y-%m-%d" > $state_file
end

function remove_state
    rm -f $state_file
end

function set_dark_macos
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
    set_wallpaper_macos "Black"
end

function set_dark_kde
    set_theme_kde "dark"
    set_wallpaper_kde "Black"
end

# Handle init subcommand (for activation scripts)
if test (count $argv) -gt 0 && test "$argv[1]" = "init"
    if is_macos
        set_dark_macos
        echo "Set dark mode and wallpaper (init)"
    else if is_kde
        set_dark_kde
        echo "Set dark mode and wallpaper (init)"
    else
        echo "Unsupported platform"
        exit 1
    end
    remove_state
    exit 0
end

# Main logic (toggle)
if is_macos
    set current_theme (get_current_theme_macos)

    if test "$current_theme" = "true"
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
        set_wallpaper_macos "Silver"
        echo "Switched to Light appearance"
    else
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
        set_wallpaper_macos "Black"
        echo "Switched to Dark appearance"
    end

    write_state
    open_settings_macos
else if is_kde
    set current_theme (get_current_theme_kde)

    if test "$current_theme" = "true"
        set_theme_kde "light"
        set_wallpaper_kde "Silver"
        echo "Switched to Light appearance"
    else
        set_theme_kde "dark"
        set_wallpaper_kde "Black"
        echo "Switched to Dark appearance"
    end

    write_state
    open_settings_kde
else
    echo "Unsupported platform or desktop environment"
    exit 1
end
