{ lib, ... }:

let
  downloadsDir = "/storage/data/media/downloads/lidarr";
in
{
  # /storage/data/music is created by ../navidrome.nix (navidrome:media 2775);
  # lidarr writes via membership in `media`.
  systemd.tmpfiles.rules = [
    "d ${downloadsDir} 2775 lidarr media -"
  ];

  services.lidarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.bindaddress = "*";
    };
  };

  systemd.services.lidarr = {
    serviceConfig.UMask = lib.mkForce "0002";
    unitConfig.RequiresMountsFor = [ "/storage" ];
  };
}
