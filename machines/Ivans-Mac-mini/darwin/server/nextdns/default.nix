{ config, ... }:

{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDnsApiKey";
    };
    nextdns-profile-mini = {
      key = "nextDnsProfileMini";
    };
    nextdns-profile-router = {
      key = "nextDnsProfileRouter";
    };
  };

  local.services.nextdns-mgmt.mini = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-mini.path;
    profileFile = ../../../../../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.router = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-router.path;
    profileFile = ../../../../../configs/nextdns-profile.json;
  };
}
