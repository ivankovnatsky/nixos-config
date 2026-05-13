{ config, pkgs, ... }:

# Replaces machines/Ivans-Mac-mini/home/server/navidrome (launchd) with the
# NixOS upstream services.navidrome module on a3. Music root lives at
# /storage/data/music — owned navidrome:media 2775 here, with lidarr writing
# via membership in the shared `media` group. Navidrome runs as its own
# navidrome:navidrome user; the upstream module bind-mounts MusicFolder
# read-only into the unit, so navidrome only reads.

let
  musicDir = "/storage/data/music";
in
{
  # Owned navidrome:media 2775 so lidarr (in `media`) can write imports while
  # navidrome reads as owner. Without this, music would only exist as a
  # side-effect of lidarr.nix's tmpfiles rule — fragile if lidarr is moved.
  systemd.tmpfiles.rules = [
    "d ${musicDir} 2775 navidrome media -"
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
