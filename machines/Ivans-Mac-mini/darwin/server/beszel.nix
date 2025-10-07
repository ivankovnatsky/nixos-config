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

      ProgramArguments = [
        "${pkgs.beszel}/bin/beszel-hub"
        "serve"
        "--http"
        "${config.flags.miniIp}:8091"
        "--dir"
        "/Volumes/Storage/Data/.beszel-hub"
      ];
    };
  };

  # Ensure state directory exists
  system.activationScripts.beszel-hub.text = ''
    mkdir -p /Volumes/Storage/Data/.beszel-hub
  '';

  # Beszel Agent (monitoring mini itself)
  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    hubPublicKey = config.secrets.beszel.hubPublicKey;
  };
}
