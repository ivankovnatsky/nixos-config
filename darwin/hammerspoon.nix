{
  local.launchd.services.hammerspoon = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a Hammerspoon";
    runAtLoad = true;
    keepAlive = false;
  };
}
