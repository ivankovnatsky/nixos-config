#!/usr/bin/env fish

# Function to get the current theme
function get_current_theme
    osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode'
end

# Function to set wallpaper
function set_wallpaper
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

function open_settings
    # We need to close to make sure we control on which desktop the app will be
    # opened.
    osascript -e 'quit app "System Settings"'

    # Open System Settings directly to Wallpaper preferences
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

# Function to get current date and determine seasonal wallpaper
function get_seasonal_dark_wallpaper
    set month (date "+%m")
    set day (date "+%d")
    
    # Convert date to a comparable number (MMDD format)
    set current_date (math $month x 100 + $day)
    
    # Oct 15 (1015) to Apr 15 (415) should use Black
    if test $current_date -ge 1015 -o $current_date -le 415
        echo "Black"
    else
        echo "Stone"
    end
end

# Get the current theme
set current_theme (get_current_theme)

# Toggle the theme and set wallpaper
if test "$current_theme" = "true"
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
    set_wallpaper "Silver"
    echo "Switched to Light appearance"
else
    set dark_wallpaper (get_seasonal_dark_wallpaper)
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
    set_wallpaper $dark_wallpaper
    echo "Switched to Dark appearance"
end

open_settings
