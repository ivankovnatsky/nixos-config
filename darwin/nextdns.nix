{ config, username, ... }:

{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDnsApiKey";
      owner = username;
    };
    nextdns-profile-pro = {
      key = "nextDnsProfilePro";
      owner = username;
    };
    nextdns-profile-air = {
      key = "nextDnsProfileAir";
      owner = username;
    };
    nextdns-profile-mini = {
      key = "nextDnsProfileMini";
      owner = username;
    };
    nextdns-profile-phone = {
      key = "nextDnsProfilePhone";
      owner = username;
    };
    nextdns-profile-asus = {
      key = "nextDnsProfileAsus";
      owner = username;
    };
  };

  local.services.nextdns-mgmt.pro = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-pro.path;
    profileFile = ../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.air = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-air.path;
    profileFile = ../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.phone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-phone.path;
    profileFile = ../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.mini = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-mini.path;
    profileFile = ../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.asus = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-asus.path;
    profileFile = ../configs/nextdns-profile.json;
  };
}
