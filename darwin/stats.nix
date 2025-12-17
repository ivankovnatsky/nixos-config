{
  local.launchd.services.stats = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a Stats";
    runAtLoad = true;
    keepAlive = false;
  };
}
