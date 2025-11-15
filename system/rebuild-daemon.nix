{ config, lib, username ? null, ... }:
let
  # Determine the base path for the config based on hostname
  # Ivans-Mac-mini uses miniStoragePath, others use user home directory
  hostName = config.networking.hostName or "";

  basePath =
    if hostName == "Ivans-Mac-mini" then
      config.flags.miniStoragePath
    else
      "${config.users.users.${username}.home}";

in
{
  local.services.rebuildDaemon = {
    enable = true;
    configPath = "${basePath}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
