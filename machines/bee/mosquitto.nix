{ config, pkgs, ... }:
{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = config.flags.beeIp;
        port = 1883;
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  # Open firewall for MQTT
  networking.firewall.allowedTCPPorts = [ 1883 ];
}
