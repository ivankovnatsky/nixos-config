-- Create a table in the global scope to hold our functions
_G.system_appearance = {}

-- Detect operating system
local function get_os()
  local os = vim.loop.os_uname().sysname
  return os
end

local current_os = get_os()

-- Function to check macOS appearance
local function get_macos_appearance()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result:match("Dark") then
      return "dark"
    else
      return "light"
    end
  end
  return "light" -- Default to light if we can't determine
end

-- Function to check KDE Plasma appearance
local function get_plasma_appearance()
  -- Check for KDE Plasma theme by reading kdeglobals file directly
  -- First check for LookAndFeelPackage which is more reliable
  local handle = io.popen("grep -i 'LookAndFeelPackage' ~/.config/kdeglobals 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and (result:match("dark") or result:match("Dark") or result:match("black") or result:match("Black")) then
      return "dark"
    elseif result and result:len() > 0 then
      -- If we found a LookAndFeelPackage but it doesn't contain 'dark', assume light
      return "light"
    end
  end
  
  -- Fallback: check ColorScheme in kdeglobals
  handle = io.popen("grep -i 'ColorScheme' ~/.config/kdeglobals 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and (result:match("dark") or result:match("Dark") or result:match("black") or result:match("Black")) then
      return "dark"
    elseif result and result:len() > 0 then
      return "light"
    end
  end
  
  -- Check if we have dark colors in the General section
  handle = io.popen("grep -A 10 '\\[General\\]' ~/.config/kdeglobals | grep -i 'BackgroundNormal' 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    -- Parse the RGB values - dark themes typically have low background values
    local r, g, b = result:match("(%d+),(%d+),(%d+)")
    if r and g and b then
      r, g, b = tonumber(r), tonumber(g), tonumber(b)
      -- If average RGB is less than 128, it's likely a dark theme
      if (r + g + b) / 3 < 128 then
        return "dark"
      else
        return "light"
      end
    end
  end
  
  return "light" -- Default to light if we can't determine
end

-- Function to check GNOME appearance
local function get_gnome_appearance()
  -- Check if gsettings is available
  local check_cmd = io.popen("command -v gsettings")
  local has_gsettings = check_cmd:read("*a") ~= ""
  check_cmd:close()
  
  if not has_gsettings then
    return "light" -- Default if gsettings not available
  end
  
  -- Check GNOME color scheme
  local handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result:match("dark") then
      return "dark"
    else
      return "light"
    end
  end
  
  -- Fallback to checking prefer-dark-theme (older GNOME versions)
  handle = io.popen("gsettings get org.gnome.desktop.interface gtk-theme")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result:match("dark") or result:match("Dark") then
      return "dark"
    else
      return "light"
    end
  end
  
  return "light" -- Default to light if we can't determine
end

-- Function to get current system appearance based on OS
local function get_system_appearance()
  if current_os == "Darwin" then
    return get_macos_appearance()
  elseif current_os == "Linux" then
    -- Check if we're in a GNOME environment
    local check_cmd = io.popen("command -v gsettings")
    local has_gsettings = check_cmd:read("*a") ~= ""
    check_cmd:close()
    
    if has_gsettings then
      return get_gnome_appearance()
    else
      -- Try Plasma if GNOME is not detected
      return get_plasma_appearance()
    end
  else
    return "light" -- Default for other OSes
  end
end

-- Variable to store the current appearance
local current_appearance = get_system_appearance()

-- Function to set the background
local function set_background()
  vim.o.background = current_appearance
end

-- Function to check and update appearance asynchronously
function _G.system_appearance.check_appearance()
  vim.schedule(function()
    local new_appearance = get_system_appearance()
    if new_appearance ~= current_appearance then
      current_appearance = new_appearance
      set_background()
      print("Appearance changed to: " .. new_appearance)
    end
  end)
end

-- Set up timer for periodic checking
local check_interval = 5000 -- Check every 5 seconds (adjust as needed)
local timer = vim.loop.new_timer()
timer:start(0, check_interval, vim.schedule_wrap(_G.system_appearance.check_appearance))

-- Set initial background
set_background()

-- Set up the autocommand
vim.cmd([[
  augroup SystemAppearance
    autocmd!
    autocmd FocusGained * lua _G.system_appearance.check_appearance()
  augroup END
]])
