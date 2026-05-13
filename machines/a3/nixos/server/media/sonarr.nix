{ lib, ... }:

let
  tvDir = "/storage/data/media/tv";
  downloadsDir = "/storage/data/media/downloads/tv-sonarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${tvDir}        2775 sonarr media -"
    "d ${downloadsDir} 2775 sonarr media -"
  ];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.bindaddress = "*";
    };
  };

  systemd.services.sonarr = {
    # Default UMask=0022 blocks group write; cross-arr handoff needs 0002
    # so radarr/lidarr (also in `media`) can rewrite/delete files sonarr
    # imports from the shared downloads dir.
    serviceConfig.UMask = lib.mkForce "0002";
    # Service won't start until /storage is mounted. tmpfiles ordering
    # isn't gated by this; in the rare LUKS+TPM unlock failure case,
    # phantom dirs may be created on rootfs but stay shadowed (harmless)
    # once the mount succeeds on a later boot.
    unitConfig.RequiresMountsFor = [ "/storage" ];
  };
}
