{ config, pkgs, ... }:
{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "0.0.0.0";
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
