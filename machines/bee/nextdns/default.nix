{ config, ... }:

{
  local.services.nextdns-sync = {
    enable = true;
    profiles = [ config.secrets.nextDnsProfileBee ];
  };
}
