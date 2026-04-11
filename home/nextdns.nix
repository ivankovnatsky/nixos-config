{ config, ... }:

let
  commonVars = {
    inherit (config.flags) miniWifiIp;
    inherit (config.flags) miniIp;
    inherit (config.flags) miniEn7Ip;
  };

  commonVarsFiles = {
    externalDomain = config.sops.secrets.external-domain.path;
  };
in
{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDnsApiKey";
    };
    nextdns-profile-pro = {
      key = "nextDnsProfilePro";
    };
    nextdns-profile-air = {
      key = "nextDnsProfileAir";
    };
    nextdns-profile-mini = {
      key = "nextDnsProfileMini";
    };
    nextdns-profile-phone = {
      key = "nextDnsProfilePhone";
    };
    nextdns-profile-asus = {
      key = "nextDnsProfileAsus";
    };
    nextdns-profile-lgphone = {
      key = "nextDnsProfileLgPhone";
    };
    nextdns-profile-a3 = {
      key = "nextDnsProfileA3";
    };
  };

  local.services.nextdns-mgmt.pro = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-pro.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.air = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-air.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.phone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-phone.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.mini = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-mini.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.asus = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-asus.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.lgphone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-lgphone.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.a3 = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-a3.path;
    profileFile = ../configs/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };
}
