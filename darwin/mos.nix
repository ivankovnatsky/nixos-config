{
  local.launchd.services.mos = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a Mos";
    runAtLoad = true;
    keepAlive = false;
  };
}
