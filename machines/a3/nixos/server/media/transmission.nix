{ config, pkgs, ... }:

# Mirrors machines/Ivans-Mac-mini/home/server/media/transmission.nix settings.
# Differences from the mini:
#   * NixOS upstream `services.transmission` (systemd) instead of launchd.
#   * Storage rooted at /storage/data (LUKS-backed ext4) instead of
#     /Volumes/Storage/Data.
#   * Shared `media` group so sonarr/radarr/lidarr can read/write downloads.
#   * Credentials are rendered into a sops template (already the pattern on a3,
#     see machines/a3/nixos/server/beszel.nix). Upstream's prestart merges that
#     JSON onto settings.json via `jq --slurp add`.

let
  downloadsDir = "/storage/data/media/downloads";
  incompleteDir = "/storage/data/media/downloads/.incomplete";
  watchDir = "/storage/data/media/downloads/watchdir";
in
{
  # Upstream's BindPaths for the transmission unit references download-dir,
  # incomplete-dir, and watch-dir; if any are missing at start, systemd fails
  # mount namespace setup with status=226/NAMESPACE. Pre-create them here so
  # the unit can come up on a fresh /storage.
  systemd.tmpfiles.rules = [
    "d ${downloadsDir}  2775 transmission media -"
    "d ${incompleteDir} 2775 transmission media -"
    "d ${watchDir}      2775 transmission media -"
  ];

  sops.secrets.transmission-username = {
    key = "transmission/username";
    owner = "transmission";
    group = "media";
  };

  sops.secrets.transmission-password = {
    key = "transmission/password";
    owner = "transmission";
    group = "media";
  };

  sops.templates."transmission-credentials.json" = {
    owner = "transmission";
    group = "media";
    mode = "0440";
    content = ''
      {
        "rpc-username": "${config.sops.placeholder.transmission-username}",
        "rpc-password": "${config.sops.placeholder.transmission-password}"
      }
    '';
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    openFirewall = true;
    openRPCPort = true;
    group = "media";
    # Rendered out-of-store JSON; upstream merges it into settings.json with
    # `jq --slurp add` in its own ExecStartPre.
    credentialsFile = config.sops.templates."transmission-credentials.json".path;
    # Lets the activation script create download/incomplete/watch dirs with
    # group-writable perms so the arr services (also in `media`) can hardlink
    # imports out of them.
    downloadDirPermissions = "2775";

    settings = {
      rpc-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = true;
      rpc-whitelist-enabled = false;
      rpc-whitelist = "192.168.*.*";

      download-dir = downloadsDir;
      incomplete-dir = incompleteDir;
      incomplete-dir-enabled = true;
      watch-dir = watchDir;
      watch-dir-enabled = true;

      bind-address-ipv4 = "0.0.0.0";
      peer-port = 51413;
      peer-port-random-on-start = false;
      port-forwarding-enabled = false;

      umask = 2;
      message-level = 2;
      cache-size-mb = 4;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;

      # Keep seeding indefinitely; do not stop by ratio, seed time, or idle time.
      ratio-limit-enabled = false;
      seed-time-limit-enabled = false;
      idle-seeding-limit-enabled = false;
      script-torrent-done-enabled = false;

      speed-limit-down = 0;
      speed-limit-down-enabled = false;
      speed-limit-up = 0;
      speed-limit-up-enabled = false;

      encryption = 1;
      utp-enabled = true;
      dht-enabled = true;
      pex-enabled = true;
      lpd-enabled = false;
    };
  };

  # /storage is LUKS+TPM unlocked; gate the service on the mount so
  # we don't start (and BindPaths against an empty mountpoint) if the
  # unlock fails on boot.
  systemd.services.transmission.unitConfig.RequiresMountsFor = [ "/storage" ];
}
