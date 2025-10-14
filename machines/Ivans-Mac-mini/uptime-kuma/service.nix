{ config, pkgs, ... }:

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.uptime-kuma";
in
{
  # Uptime Kuma HTTP synthetic monitoring service
  # Web UI: https://uptime.@externalDomain@
  # Co-located with Beszel hub for centralized monitoring
  launchd.daemons.uptime-kuma = {
    serviceConfig = {
      Label = "org.nixos.uptime-kuma";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/log/launchd/uptime-kuma.out.log";
      StandardErrorPath = "/tmp/log/launchd/uptime-kuma.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        uptimeKumaScript = pkgs.writeShellScriptBin "uptime-kuma-starter" ''
          # Wait for the Storage volume to be mounted
          echo "Waiting for ${volumePath} to be available..."
          /bin/wait4path "${volumePath}"

          echo "${volumePath} is now available!"

          # Ensure data directory exists
          mkdir -p ${dataDir}

          echo "Starting Uptime Kuma..."

          # Set environment variables for Uptime Kuma
          export DATA_DIR=${dataDir}
          export HOST=${config.flags.miniIp}
          export PORT=3001
          export NODE_ENV=production

          # Launch uptime-kuma
          exec ${pkgs.uptime-kuma}/bin/uptime-kuma-server
        '';
      in
      "${uptimeKumaScript}/bin/uptime-kuma-starter";
  };
}
