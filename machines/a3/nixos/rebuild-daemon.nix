{ config, username, ... }:
let
  homePath = "${config.users.users.${username}.home}";

in
{
  local.services.rebuildDaemon = {
    enable = true;
    configPath = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
