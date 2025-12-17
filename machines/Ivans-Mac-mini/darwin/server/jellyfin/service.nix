{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.jellyfin";
  configDir = "${dataDir}/config";
  cacheDir = "${dataDir}/cache";
  logDir = "${dataDir}/log";
in
{
  # Initial Setup (manual, one-time):
  # 1. Access the web UI at https://jellyfin.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Generate API key: Administration → Dashboard → Advanced → API Keys → New API Key
  # 4. Name the key "Default" and save it in modules/secrets/default.nix under secrets.jellyfin.apiKey
  #
  # After initial setup, jellyfin-mgmt will declaratively manage:
  # - Libraries (media paths and types)
  # - Network configuration (bind address set to mini IP instead of all interfaces)

  local.launchd.services.jellyfin = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      configDir
      cacheDir
      logDir
    ];
    command = ''
      ${pkgs.jellyfin}/bin/jellyfin \
        --datadir ${dataDir} \
        --configdir ${configDir} \
        --cachedir ${cacheDir} \
        --logdir ${logDir}
    '';
  };
}
