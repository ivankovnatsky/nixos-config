{ config, ... }:

{
  local.services.nextdns-mgmt = {
    enable = true;
    apiKey = config.secrets.nextDnsApiKey;
    profileId = config.secrets.nextDnsProfileMini;
    profileFile = ../../../../../configs/nextdns-profile.json;
  };
}
