{ config, ... }:

{
  local.services.nextdns-mgmt = {
    enable = true;
    apiKey = config.secrets.nextDnsApiKey;
    profileId = config.secrets.nextDnsProfileBee;
    profileFile = ./profile.json;
  };
}
