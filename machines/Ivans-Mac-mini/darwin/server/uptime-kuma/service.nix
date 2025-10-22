{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.uptime-kuma";
in
{
  # Uptime Kuma HTTP synthetic monitoring service
  # Web UI: https://uptime.@externalDomain@
  # Co-located with Beszel hub for centralized monitoring
  local.launchd.services.uptime-kuma = {
    enable = true;
    type = "daemon";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    preStart = ''
      export PATH="${pkgs.tailscale}/bin:${pkgs.coreutils}/bin:$PATH"
    '';
    environment = {
      DATA_DIR = dataDir;
      HOST = config.flags.miniIp;
      PORT = "3001";
      NODE_ENV = "production";
    };
    command = ''
      ${pkgs.uptime-kuma}/bin/uptime-kuma-server
    '';
  };
}
