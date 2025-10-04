{ config, ... }:

{
  local.services.nextdns-mgmt = {
    enable = true;
    profiles = [ config.secrets.nextDnsProfileMini ];
  };
}
