-- Create a table in the global scope to hold our functions
_G.macos_appearance = {}

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

-- Variable to store the current appearance
local current_appearance = get_macos_appearance()

-- Function to set the background
local function set_background()
  vim.o.background = current_appearance
end

-- Function to check and update appearance asynchronously
function _G.macos_appearance.check_appearance()
  vim.schedule(function()
    local new_appearance = get_macos_appearance()
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
timer:start(0, check_interval, vim.schedule_wrap(_G.macos_appearance.check_appearance))

-- Set initial background
set_background()

-- Set up the autocommand
vim.cmd([[
  augroup MacosAppearance
    autocmd!
    autocmd FocusGained * lua _G.macos_appearance.check_appearance()
  augroup END
]])
