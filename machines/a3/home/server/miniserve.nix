{
  config,
  pkgs,
  ...
}:

let
  serveDir = "/storage/data";
in
{
  # miniserve file server on a3.
  #
  # Migrated from mini (machines/Ivans-Mac-mini/home/server/miniserve.nix):
  #   * launchd user agent → home-manager systemd user unit (NixOS).
  #   * serves /storage/data (a3's LUKS-backed data volume) instead of
  #     /Volumes/Storage/Data.
  #   * auth credentials are still keyed under `miniserve/mini/*` in sops
  #     (declared by home/sops-secrets.nix) — values are reused across hosts
  #     rather than re-encrypted under a new path.
  #
  # /storage/data/backup is a bind mount of /storage0/data/backup.

  sops.templates."miniserve-auth" = {
    content = ''
      ${config.sops.placeholder.miniserve-username}:${config.sops.placeholder.miniserve-password}
    '';
  };

  systemd.user.services.miniserve = {
    Unit = {
      Description = "miniserve file server";
      # /storage and /storage0 are LUKS+TPM unlocked at boot; ivan has
      # `linger = true`, so this user unit starts at boot independent of any
      # graphical session.
      #
      # RequiresMountsFor pulls in the proper Requires=/After= on the system
      # storage.mount and storage-data-backup.mount so we don't race LUKS
      # unlocks. The ExecStartPre
      # mountpoint check is a belt-and-suspenders guard, and the generous
      # restart budget covers slow TPM unlocks (~unlimited retries over 1h).
      RequiresMountsFor = [
        "/storage"
        "/storage/data/backup"
      ];
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      StartLimitBurst = 100;
      StartLimitIntervalSec = 3600;
    };
    Service = {
      # Refuse to start if /storage isn't mounted — otherwise miniserve would
      # happily serve the empty mountpoint dir on the root fs.
      ExecStartPre = pkgs.writeShellScript "miniserve-check-mounts" ''
        ${pkgs.util-linux}/bin/mountpoint -q /storage
        ${pkgs.util-linux}/bin/mountpoint -q /storage/data/backup
      '';
      ExecStart = pkgs.writeShellScript "miniserve-start" ''
        exec ${pkgs.miniserve}/bin/miniserve \
          --interfaces 0.0.0.0 \
          --interfaces :: \
          --auth-file ${config.sops.templates."miniserve-auth".path} \
          --upload-files /backup/Machines \
          --mkdir \
          --on-duplicate-files rename \
          ${serveDir}
      '';
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
