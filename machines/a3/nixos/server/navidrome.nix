{ config, pkgs, ... }:

# NixOS upstream services.navidrome module on a3 (replaces the mini launchd
# setup). Music lives at /storage/data/music owned ivan:media, so `rclone
# sync` over SFTP as ivan can set mtimes — only a file's owner may. navidrome
# runs PrivateUsers=true, so it reads the tree via the `other` permission
# bits; the module bind-mounts MusicFolder read-only.

let
  musicDir = "/storage/data/music";
in
{
  # ivan owns the tree so rclone can set mtimes; setgid `media` lets lidarr
  # write imports. `Z` recursively chowns the existing tree (still owned by
  # navidrome from the launchd-era migration); mode `-` leaves modes intact.
  systemd.tmpfiles.rules = [
    "d ${musicDir} 2775 ivan media -"
    "Z ${musicDir} - ivan media -"
  ];

  sops.secrets.lastFm-api-key = {
    key = "lastFm/apiKey";
    owner = "navidrome";
  };

  sops.secrets.lastFm-secret = {
    key = "lastFm/secret";
    owner = "navidrome";
  };

  sops.templates."navidrome.env" = {
    owner = "navidrome";
    mode = "0440";
    content = ''
      ND_LASTFM_APIKEY=${config.sops.placeholder.lastFm-api-key}
      ND_LASTFM_SECRET=${config.sops.placeholder.lastFm-secret}
    '';
  };

  services.navidrome = {
    enable = true;
    openFirewall = true;
    environmentFile = config.sops.templates."navidrome.env".path;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = musicDir;
      EnableTranscodingConfig = true;
      # Upstream module's systemd sandbox gives navidrome a minimal PATH
      # (coreutils/sed/systemd only) — point at the nix-store ffmpeg
      # directly so transcoding works. /nix/store is already in
      # BindReadOnlyPaths.
      FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
      Scanner.Schedule = "@every 15m";
    };
  };

  # /storage is LUKS+TPM unlocked; gate navidrome on the mount so BindPaths
  # don't fail on an empty mountpoint after a failed unlock.
  systemd.services.navidrome.unitConfig.RequiresMountsFor = [ "/storage" ];
}
