{ config, username, ... }:
let
  homePath = "${config.users.users.${username}.home}";

in
{
  services.tmuxRebuild.nixosConfigPath = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
}
