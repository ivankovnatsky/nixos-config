{ config, ... }:

{
  networking = {
    networkmanager = {
      dns = "none";
    };
  };

  services.nextdns = {
    enable = true;
    arguments = [
      "-config"
      "${config.secrets.nextDNSID}"
      "-report-client-info"
      "-auto-activate"
    ];
  };
}
