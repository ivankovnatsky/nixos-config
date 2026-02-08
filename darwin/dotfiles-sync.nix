{
  pkgs,
  ...
}:
{
  local.launchd.services.dotfiles-sync = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.dotfiles}/bin/dotfiles home sync";
    runAtLoad = true;
    keepAlive = false;
    extraServiceConfig = {
      StartInterval = 900;
    };
  };
}
