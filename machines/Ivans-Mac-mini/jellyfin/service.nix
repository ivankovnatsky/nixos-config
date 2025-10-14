{ pkgs, ... }:

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.jellyfin";
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

  launchd.user.agents.jellyfin = {
    serviceConfig = {
      Label = "com.ivankovnatsky.jellyfin";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/jellyfin.log";
      StandardErrorPath = "/tmp/agents/log/launchd/jellyfin.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        jellyfinScript = pkgs.writeShellScriptBin "jellyfin-starter" ''
          /bin/wait4path "${volumePath}"
          mkdir -p ${dataDir}
          mkdir -p ${configDir}
          mkdir -p ${cacheDir}
          mkdir -p ${logDir}
          exec ${pkgs.jellyfin}/bin/jellyfin \
            --datadir ${dataDir} \
            --configdir ${configDir} \
            --cachedir ${cacheDir} \
            --logdir ${logDir}
        '';
      in
      "${jellyfinScript}/bin/jellyfin-starter";
  };
}
