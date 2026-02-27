{
  pkgs,
  ...
}:
{
  local.launchd.services.dotfiles-shared-init = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.dotfiles}/bin/dotfiles shared init";
    runAtLoad = true;
    keepAlive = false;
    extraServiceConfig = {
      StartInterval = 900;
    };
  };
}
