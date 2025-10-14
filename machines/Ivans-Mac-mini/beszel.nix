{ config, pkgs, ... }:
{
  # Beszel Hub service
  # Note: Requires Full Disk Access in System Settings → Privacy & Security
  # to write to /Volumes/Storage (granted manually, testing if works)
  #
  # Manual restart: sudo launchctl kickstart -k system/org.nixos.beszel-hub
  launchd.daemons.beszel-hub = {
    serviceConfig = {
      Label = "org.nixos.beszel-hub";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/log/launchd/beszel-hub.out.log";
      StandardErrorPath = "/tmp/log/launchd/beszel-hub.error.log";
      ThrottleInterval = 10;
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        beszelScript = pkgs.writeShellScriptBin "beszel-hub-starter" ''
          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"

          echo "/Volumes/Storage is now available!"
          echo "Starting Beszel Hub..."

          # Launch beszel-hub
          exec ${pkgs.beszel}/bin/beszel-hub serve \
            --http ${config.flags.miniIp}:8091 \
            --dir /Volumes/Storage/Data/.beszel-hub
        '';
      in
      "${beszelScript}/bin/beszel-hub-starter";
  };

  # Ensure state directory exists
  system.activationScripts.beszel-hub.text = ''
    mkdir -p /Volumes/Storage/Data/.beszel-hub
  '';

  # Beszel Agent (monitoring mini itself)
  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    listenAddress = config.flags.miniIp;
    hubPublicKey = config.secrets.beszel.hubPublicKey;
  };

  # Beszel management (declarative system sync)
  local.services.beszel-mgmt = {
    enable = true;
    email = config.secrets.beszel.email;
    password = config.secrets.beszel.password;
    systems = [
      {
        name = "bee";
        host = config.flags.beeIp;
        port = "45876";
      }
      {
        name = "Ivans-Mac-mini";
        host = config.flags.miniIp;
        port = "45876";
      }
    ];
  };
}
