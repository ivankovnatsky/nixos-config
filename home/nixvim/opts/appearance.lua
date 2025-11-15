-- Create a table in the global scope to hold our functions
_G.system_appearance = {}

-- Detect operating system
local function get_os()
  local os = vim.loop.os_uname().sysname
  return os
end

local current_os = get_os()
local current_appearance = "light" -- Default appearance
local last_check = 0
local debounce_time = 10000 -- 10 seconds in milliseconds

-- Function to check macOS appearance asynchronously
local function get_macos_appearance(callback)
  vim.system(
    { "defaults", "read", "-g", "AppleInterfaceStyle" },
    { text = true },
    function(obj)
      if obj.code == 0 and obj.stdout:match("Dark") then
        callback("dark")
      else
        callback("light")
      end
    end
  )
end

-- Function to check KDE Plasma appearance asynchronously
local function get_plasma_appearance(callback)
  local kdeglobals_file = os.getenv("HOME") .. "/.config/kdeglobals"

  -- Check if file exists
  vim.loop.fs_stat(kdeglobals_file, function(err, stat)
    if err or not stat then
      callback("light")
      return
    end

    -- Check LookAndFeelPackage first (most reliable)
    vim.system(
      { "sh", "-c", "grep -i 'LookAndFeelPackage' " .. kdeglobals_file .. " 2>/dev/null" },
      { text = true },
      function(obj)
        if obj.code == 0 and obj.stdout then
          local result = obj.stdout
          if result:match("dark") or result:match("Dark") or result:match("black") or result:match("Black") then
            callback("dark")
            return
          elseif result:len() > 0 then
            callback("light")
            return
          end
        end

        -- Fallback: check ColorScheme
        vim.system(
          { "sh", "-c", "grep -i '^ColorScheme=' " .. kdeglobals_file .. " 2>/dev/null" },
          { text = true },
          function(obj2)
            if obj2.code == 0 and obj2.stdout and not obj2.stdout:match("Hash") then
              local result = obj2.stdout
              if result:match("dark") or result:match("Dark") or result:match("black") or result:match("Black") then
                callback("dark")
                return
              elseif result:len() > 0 then
                callback("light")
                return
              end
            end

            -- Final fallback: check BackgroundNormal RGB values
            vim.system(
              { "sh", "-c", "grep -A 10 '\\[Colors:Window\\]' " .. kdeglobals_file .. " | grep 'BackgroundNormal' 2>/dev/null" },
              { text = true },
              function(obj3)
                if obj3.code == 0 and obj3.stdout then
                  local r, g, b = obj3.stdout:match("(%d+),(%d+),(%d+)")
                  if r and g and b then
                    r, g, b = tonumber(r), tonumber(g), tonumber(b)
                    if (r + g + b) / 3 < 128 then
                      callback("dark")
                      return
                    end
                  end
                end
                callback("light")
              end
            )
          end
        )
      end
    )
  end)
end

-- Function to check GNOME appearance asynchronously
local function get_gnome_appearance(callback)
  -- Check if gsettings is available
  vim.system(
    { "sh", "-c", "command -v gsettings" },
    { text = true },
    function(obj)
      if obj.code ~= 0 then
        callback("light")
        return
      end

      -- Check GNOME color scheme
      vim.system(
        { "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" },
        { text = true },
        function(obj2)
          if obj2.code == 0 and obj2.stdout:match("dark") then
            callback("dark")
            return
          end

          -- Fallback: check gtk-theme
          vim.system(
            { "gsettings", "get", "org.gnome.desktop.interface", "gtk-theme" },
            { text = true },
            function(obj3)
              if obj3.code == 0 and (obj3.stdout:match("dark") or obj3.stdout:match("Dark")) then
                callback("dark")
              else
                callback("light")
              end
            end
          )
        end
      )
    end
  )
end

-- Function to get current system appearance based on OS (async)
local function get_system_appearance(callback)
  if current_os == "Darwin" then
    get_macos_appearance(callback)
  elseif current_os == "Linux" then
    -- Check if we're in a GNOME environment first
    vim.system(
      { "sh", "-c", "command -v gsettings" },
      { text = true },
      function(obj)
        if obj.code == 0 then
          get_gnome_appearance(callback)
        else
          get_plasma_appearance(callback)
        end
      end
    )
  else
    callback("light") -- Default for other OSes
  end
end

-- Function to set the background
local function set_background(appearance)
  vim.schedule(function()
    vim.o.background = appearance
  end)
end

-- Function to check and update appearance with debouncing
function _G.system_appearance.check_appearance()
  local now = vim.loop.now()

  -- Debounce: don't check if we checked recently
  if now - last_check < debounce_time then
    return
  end

  last_check = now

  get_system_appearance(function(new_appearance)
    if new_appearance ~= current_appearance then
      current_appearance = new_appearance
      set_background(new_appearance)
      vim.schedule(function()
        vim.notify("Appearance changed to: " .. new_appearance, vim.log.levels.INFO)
      end)
    end
  end)
end

-- Set initial appearance
get_system_appearance(function(appearance)
  current_appearance = appearance
  set_background(appearance)
end)

-- Set up the autocommand (only check on focus, no aggressive timer)
vim.api.nvim_create_augroup("SystemAppearance", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
  group = "SystemAppearance",
  callback = _G.system_appearance.check_appearance,
  desc = "Check system appearance when window gains focus"
})
