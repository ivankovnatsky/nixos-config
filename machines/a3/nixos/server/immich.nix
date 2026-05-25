{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /storage/data/photos 0700 immich immich -"
  ];

  # Save api key in sops secrets: API key from web UI → Account Settings → API
  # Keys.
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/storage/data/photos";
  };

  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/storage" ];
}
