{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /storage/data/photos 0700 immich immich -"
  ];

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/storage/data/photos";
  };

  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/storage" ];
}
