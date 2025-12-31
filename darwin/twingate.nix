{
  local.launchd.services.twingate = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a Twingate";
    runAtLoad = true;
    keepAlive = false;
  };
}
