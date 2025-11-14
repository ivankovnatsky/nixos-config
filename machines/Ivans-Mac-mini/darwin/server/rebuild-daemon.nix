{ config, ... }:
{
  local.services.rebuildDaemon = {
    enable = true;
    configPath = "${config.flags.miniStoragePath}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
