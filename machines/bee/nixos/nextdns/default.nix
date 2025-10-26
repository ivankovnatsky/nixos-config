{ config, ... }:

{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDnsApiKey";
    };
    nextdns-profile-bee = {
      key = "nextDnsProfileBee";
    };
  };

  local.services.nextdns-mgmt.bee = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-bee.path;
    profileFile = ../../../../configs/nextdns-profile.json;
  };
}
