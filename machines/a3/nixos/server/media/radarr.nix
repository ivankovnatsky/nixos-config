{ lib, ... }:

let
  moviesDir = "/storage/data/media/movies";
  downloadsDir = "/storage/data/media/downloads/radarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${moviesDir}    2775 radarr media -"
    "d ${downloadsDir} 2775 radarr media -"
  ];

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.bindaddress = "*";
    };
  };

  systemd.services.radarr = {
    serviceConfig.UMask = lib.mkForce "0002";
    unitConfig.RequiresMountsFor = [ "/storage" ];
  };
}
