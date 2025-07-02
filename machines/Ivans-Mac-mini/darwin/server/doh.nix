{
  config,
  lib,
  pkgs,
  ...
}: {
  local.services.doh-server = {
    enable = true;
    settings = {
      listen = [
        "127.0.0.1:8053"
        "${config.flags.miniIp}:8053"
      ];
      upstream = [ "udp:127.0.0.1:53" ];
    };
  };
}
