{
  config,
  pkgs,
  ...
}:

# Seeding control settings (crucial for Sonarr cleanup):
# * ratio-limit: 1.0 (lowered from 2.0 for quicker cleanup)
# * ratio-limit-enabled: true (enables Sonarr to remove completed downloads)
# * seed-time-limit: 30 minutes (reduced from 60)
# * seed-time-limit-enabled: true (enables seed time limit for Sonarr cleanup)
# * idle-seeding-limit: 30 minutes (additional idle time before pausing)
# * idle-seeding-limit-enabled: true (extra measure for cleanup)

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.transmission";
  downloadsDir = "${volumePath}/Data/Media/Downloads";
  incompleteDir = "${volumePath}/Data/Media/Downloads/.incomplete";
  watchDir = "${volumePath}/Data/Media/Downloads/Watchdir";

  settingsJson = pkgs.writeText "transmission-settings.json" (
    builtins.toJSON {
      rpc-enabled = true;
      rpc-bind-address = config.flags.miniIp;
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = true;
      rpc-username = config.secrets.transmission.username;
      rpc-password = config.secrets.transmission.password;
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
  launchd.user.agents.transmission = {
    serviceConfig = {
      Label = "com.ivankovnatsky.transmission";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/transmission.log";
      StandardErrorPath = "/tmp/agents/log/launchd/transmission.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        transmissionScript = pkgs.writeShellScriptBin "transmission-starter" ''
          /bin/wait4path "${volumePath}"

          # Wait for network interface to have the correct IP
          echo "Waiting for network interface with IP ${config.flags.miniIp}..."
          TIMEOUT=60
          COUNTER=0
          while ! ifconfig | grep -q "${config.flags.miniIp}"; do
            if [ $COUNTER -ge $TIMEOUT ]; then
              echo "Network timeout after $TIMEOUT seconds!"
              exit 1
            fi
            echo "Waiting for ${config.flags.miniIp}... ($COUNTER/$TIMEOUT)"
            sleep 1
            COUNTER=$((COUNTER+1))
          done
          echo "Network interface ready with IP ${config.flags.miniIp}"

          mkdir -p ${dataDir}
          mkdir -p ${downloadsDir}
          mkdir -p ${incompleteDir}
          mkdir -p ${watchDir}

          # Copy settings if needed
          if [ ! -f "${dataDir}/settings.json" ]; then
            cp ${settingsJson} ${dataDir}/settings.json
          fi

          exec ${pkgs.transmission_4}/bin/transmission-daemon \
            --foreground \
            --config-dir ${dataDir} \
            --logfile ${dataDir}/transmission.log
        '';
      in
      "${transmissionScript}/bin/transmission-starter";
  };
}
