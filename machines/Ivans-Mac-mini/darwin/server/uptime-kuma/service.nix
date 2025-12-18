{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.uptime-kuma";
in
{
  # Uptime Kuma HTTP synthetic monitoring service
  # Web UI: https://uptime.@externalDomain@
  # User-agent to access /Volumes/Storage after login
  # See: claude/issues/LAUNCHD-BOOT-FAILURE.md
  local.launchd.services.uptime-kuma = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    preStart = ''
      export PATH="${pkgs.nixpkgs-darwin-old-release.tailscale}/bin:${pkgs.coreutils}/bin:$PATH"
    '';
    environment = {
      DATA_DIR = dataDir;
      HOST = config.flags.miniIp;
      PORT = "3001";
      NODE_ENV = "production";
    };
    command = ''
      ${pkgs.nixpkgs-darwin-old-release.uptime-kuma}/bin/uptime-kuma-server
    '';
  };
}
