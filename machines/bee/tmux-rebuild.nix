{ username, ... }:
{
  # Configure the tmux rebuild service
  local.services.tmuxRebuild = {
    enable = true;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "/storage/Sources/github.com/ivankovnatsky/nixos-config"; # Use the username variable in the path
  };
}
