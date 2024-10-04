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

# Get the current theme
set current_theme (get_current_theme)

# Toggle the theme and set wallpaper
if test "$current_theme" = "true"
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
    set_wallpaper "Silver"
    echo "Switched to Light appearance"
else
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
    set_wallpaper "Stone"
    echo "Switched to Dark appearance"
end
