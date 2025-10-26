{ username, ... }:
{
  # Configure the tmux rebuild service
  # Disabled in favor of rebuild-daemon
  local.services.tmuxRebuild = {
    enable = false;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "/home/ivan/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
