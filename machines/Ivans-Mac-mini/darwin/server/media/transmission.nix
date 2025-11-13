{ config
, pkgs
, ...
}:

# Seeding control settings (crucial for Sonarr cleanup):
# * ratio-limit: 1.0 (lowered from 2.0 for quicker cleanup)
# * ratio-limit-enabled: true (enables Sonarr to remove completed downloads)
# * seed-time-limit: 30 minutes (reduced from 60)
# * seed-time-limit-enabled: true (enables seed time limit for Sonarr cleanup)
# * idle-seeding-limit: 30 minutes (additional idle time before pausing)
# * idle-seeding-limit-enabled: true (extra measure for cleanup)

let
  dataDir = "${config.flags.miniStoragePath}/.transmission";
  downloadsDir = "${config.flags.miniStoragePath}/Media/Downloads";
  incompleteDir = "${config.flags.miniStoragePath}/Media/Downloads/.incomplete";
  watchDir = "${config.flags.miniStoragePath}/Media/Downloads/Watchdir";

  # Base settings template without secrets
  settingsTemplate = pkgs.writeText "transmission-settings-template.json" (
    builtins.toJSON {
      rpc-enabled = true;
      rpc-bind-address = config.flags.miniIp;
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = true;
      rpc-username = "@TRANSMISSION_USERNAME@";
      rpc-password = "@TRANSMISSION_PASSWORD@";
      rpc-whitelist-enabled = false;
      rpc-whitelist = "192.168.*.*";

      download-dir = downloadsDir;
      incomplete-dir = incompleteDir;
      incomplete-dir-enabled = true;
      watch-dir = watchDir;
      watch-dir-enabled = true;

      bind-address-ipv4 = config.flags.miniIp;
      peer-port = 51413;
      peer-port-random-on-start = false;
      port-forwarding-enabled = false;

      umask = 2;
      message-level = 2;
      cache-size-mb = 4;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;

      ratio-limit = 1.0;
      ratio-limit-enabled = true;
      seed-time-limit = 30;
      seed-time-limit-enabled = true;
      idle-seeding-limit = 30;
      idle-seeding-limit-enabled = true;
      script-torrent-done-enabled = true;

      speed-limit-down = 0;
      speed-limit-down-enabled = false;
      speed-limit-up = 0;
      speed-limit-up-enabled = false;

      encryption = 1;
      utp-enabled = true;
      dht-enabled = true;
      pex-enabled = true;
      lpd-enabled = false;
    }
  );
in
{
  sops.secrets.transmission-username = {
    key = "transmission/username";
    owner = "ivan";
  };

  sops.secrets.transmission-password = {
    key = "transmission/password";
    owner = "ivan";
  };

  local.launchd.services.transmission = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      downloadsDir
      incompleteDir
      watchDir
    ];
    preStart = ''
      # Read secrets from sops
      TRANSMISSION_USERNAME=$(cat ${config.sops.secrets.transmission-username.path})
      TRANSMISSION_PASSWORD=$(cat ${config.sops.secrets.transmission-password.path})

      # Generate settings.json with secrets substituted
      ${pkgs.gnused}/bin/sed \
        -e "s|@TRANSMISSION_USERNAME@|$TRANSMISSION_USERNAME|g" \
        -e "s|@TRANSMISSION_PASSWORD@|$TRANSMISSION_PASSWORD|g" \
        ${settingsTemplate} > ${dataDir}/settings.json

      chmod 600 ${dataDir}/settings.json
    '';
    command = ''
      ${pkgs.transmission_4}/bin/transmission-daemon \
        --foreground \
        --config-dir ${dataDir} \
        --logfile ${dataDir}/transmission.log
    '';
  };
}
