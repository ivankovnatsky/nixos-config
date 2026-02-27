{
  pkgs,
  ...
}:
{
  local.launchd.services.dotfiles-shared-deploy = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.dotfiles}/bin/dotfiles shared init && ${pkgs.dotfiles}/bin/dotfiles shared deploy";
    runAtLoad = true;
    keepAlive = false;
    extraServiceConfig = {
      StartInterval = 900;
    };
  };
}
