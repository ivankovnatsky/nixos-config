{ config, ... }:

{
  local.services.nextdns-mgmt.mini = {
    enable = true;
    apiKey = config.secrets.nextDnsApiKey;
    profileId = config.secrets.nextDnsProfileMini;
    profileFile = ../../../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.router = {
    enable = true;
    apiKey = config.secrets.nextDnsApiKey;
    profileId = config.secrets.nextDnsProfileRouter;
    profileFile = ../../../configs/nextdns-profile.json;
  };
}
