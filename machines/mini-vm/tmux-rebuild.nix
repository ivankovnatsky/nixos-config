{ username, ... }:
{
  # Configure the tmux rebuild service
  local.services.tmuxRebuild = {
    enable = true;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "/mnt/mac/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config"; # Path to Mac's filesystem via Orbstack mount
  };
}