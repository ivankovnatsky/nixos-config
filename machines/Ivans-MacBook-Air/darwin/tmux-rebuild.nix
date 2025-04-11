{ config, username, ... }:
let
  homePath = "${config.users.users.${username}.home}";

in
{
  local.services.tmuxRebuild.nixosConfigPath = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
}
