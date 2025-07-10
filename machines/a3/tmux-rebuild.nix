{ config, username, ... }:
let
  homePath = "${config.users.users.${username}.home}";
in
{
  # Configure the tmux rebuild service
  local.services.tmuxRebuild = {
    enable = true;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config"; # Use home path variable
  };
}
