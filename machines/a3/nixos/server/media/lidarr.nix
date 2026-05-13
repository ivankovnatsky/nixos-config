{ lib, ... }:

let
  musicDir = "/storage/data/music";
  downloadsDir = "/storage/data/media/downloads/lidarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${musicDir}     2775 lidarr media -"
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
