{ config, pkgs, ... }:

# Replaces machines/Ivans-Mac-mini/home/server/navidrome (launchd) with the
# NixOS upstream services.navidrome module on a3. Music root lives at
# /storage/data/music — owned ivan:media 2775 here. `ivan` owns it because
# the library is populated by `rclone sync` over SFTP logging in as `ivan`,
# and only a file's owner (or root) may set its mtime via utimes() — group
# write is not enough, so a non-owner rclone run fails every file with
# "SetModTime failed: permission denied". lidarr writes imports via the
# shared `media` group (setgid dir). Navidrome runs as its own static
# navidrome:navidrome system user with PrivateUsers=true, which squashes
# unmapped groups inside its namespace — so it reads the library through
# the tree's `other` permission bits (files 0644, dirs 2755/2775), not via
# group. The upstream module bind-mounts MusicFolder read-only into the
# unit, so navidrome only ever reads.

let
  musicDir = "/storage/data/music";
in
{
  # Owned ivan:media 2775: `ivan` owns the tree so `rclone sync` over SFTP
  # (which logs in as ivan) can set mtimes; setgid `media` lets lidarr (in
  # `media`) write imports. Declaring it here also keeps music existing
  # independently of lidarr.nix's tmpfiles rule.
  #
  # `Z` recursively reconciles ownership on existing deployments: the `d`
  # rule is a no-op once the directory exists, so without `Z` the files
  # still owned by navidrome (from the launchd-era migration) keep failing
  # rclone's SetModTime. mode `-` recursively chowns without touching any
  # file modes — the existing tree is files 0644 / dirs 2755-2775, already
  # world-readable, so navidrome keeps read access via its `other` bits.
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
