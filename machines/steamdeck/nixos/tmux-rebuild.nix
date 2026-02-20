{ config, username, ... }:
let
  homePath = "${config.users.users.${username}.home}";
in
{
  local.services.tmuxRebuild = {
    enable = true;
    autoStart = true;
    autoRebuild = false;
    username = username;
    nixosConfigPath = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
