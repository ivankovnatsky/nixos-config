hs.window.animationDuration = 0
hs.window.setShadows(false)

ext = {
  frame = {},
  win = {},
  app = {},
  utils = {},
  cache = {},
  watchers = {},
}

local mash = { "alt" }

hs.fnutils.each({
  { key = "0", app = "Finder" },
  { key = "1", app = "iTerm" },
  { key = "2", app = nil },
  { key = "3", app = "Chromium" },
  { key = "4", app = "Safari" },
  { key = "5", app = "Messages" },
  { key = "6", app = "Calendar" },
  { key = "7", app = "Reminders" },
  { key = "8", app = "Activity Monitor" },
  { key = "9", app = "System Settings" },
}, function(object)
  hs.hotkey.bind(mash, object.key, function()
    local appToLaunch = object.app
    if object.key == "2" then
      local currentWeekday = tonumber(os.date("%w")) -- Sunday = 0, Monday = 1, ..., Saturday = 6
      if currentWeekday == 0 or currentWeekday == 6 then -- weekend
        appToLaunch = "Safari"
      else -- weekday
        appToLaunch = "Firefox"
      end
    end
    ext.app.forceLaunchOrFocus(appToLaunch)
  end)
end)

-- https://github.com/szymonkaliski/Dotfiles/blob/b5a640336efc9fde1e8048c2894529427746076f/Dotfiles/hammerspoon/init.lua#L411-L440
function ext.app.forceLaunchOrFocus(appName)
  -- first focus with hammerspoon
  hs.application.launchOrFocus(appName)

  -- clear timer if exists
  if ext.cache.launchTimer then
    ext.cache.launchTimer:stop()
  end

  -- wait 500ms for window to appear and try hard to show the window
  ext.cache.launchTimer = hs.timer.doAfter(0.5, function()
    local frontmostApp = hs.application.frontmostApplication()
    local frontmostWindows = hs.fnutils.filter(frontmostApp:allWindows(), function(win)
      return win:isStandard()
    end)

    -- break if this app is not frontmost (when/why?)
    if frontmostApp:title() ~= appName then
      print("Expected app in front: " .. appName .. " got: " .. frontmostApp:title())
      return
    end

    if #frontmostWindows == 0 then
      -- check if there's app name in window menu (Calendar, Messages, etc...)
      if frontmostApp:findMenuItem({ "Window", appName }) then
        -- select it, usually moves to space with this window
        frontmostApp:selectMenuItem({ "Window", appName })
      else
        -- otherwise send cmd-n to create new window
        hs.eventtap.keyStroke({ "cmd" }, "n")
      end
    end
  end)
end

function reloadConfig(files)
  doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")
