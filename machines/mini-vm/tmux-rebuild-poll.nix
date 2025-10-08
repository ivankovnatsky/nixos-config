{ username, ... }:
{
  local.services.tmuxRebuildPoll = {
    enable = true;
    username = username;
    nixosConfigPath = "/mnt/mac/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config";
    pollInterval = 2;
  };
}
