{ username, ... }:
{
  # Configure the tmux rebuild service
  local.services.tmuxRebuild = {
    enable = true;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "/home/ivan/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
