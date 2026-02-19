{
  local.launchd.services.mac-mouse-fix = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a 'Mac Mouse Fix'";
    runAtLoad = true;
    keepAlive = false;
  };
}
