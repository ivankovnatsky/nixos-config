{
  local.launchd.services.linearmouse = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a LinearMouse";
    runAtLoad = true;
    keepAlive = false;
  };
}
