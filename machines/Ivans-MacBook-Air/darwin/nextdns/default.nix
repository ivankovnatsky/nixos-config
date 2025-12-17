{ config, ... }:

{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDnsApiKey";
      owner = "ivan";
    };
    nextdns-profile-pro = {
      key = "nextDnsProfilePro";
      owner = "ivan";
    };
    nextdns-profile-air = {
      key = "nextDnsProfileAir";
      owner = "ivan";
    };
    nextdns-profile-phone = {
      key = "nextDnsProfilePhone";
      owner = "ivan";
    };
    nextdns-profile-asus = {
      key = "nextDnsProfileAsus";
      owner = "ivan";
    };
  };

  local.services.nextdns-mgmt.pro = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-pro.path;
    profileFile = ../../../../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.air = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-air.path;
    profileFile = ../../../../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.phone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-phone.path;
    profileFile = ../../../../configs/nextdns-profile.json;
  };

  local.services.nextdns-mgmt.asus = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-asus.path;
    profileFile = ../../../../configs/nextdns-profile.json;
  };
}
