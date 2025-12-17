{
  local.launchd.services.amethyst = {
    enable = true;
    type = "user-agent";
    command = "/usr/bin/open -a Amethyst";
    runAtLoad = true;
    keepAlive = false;
  };
}
