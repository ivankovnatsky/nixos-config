{ config, ... }:

let
  commonVars = {
    inherit (config.flags) miniIp miniWifiIp a3Ip a3WifiIp;
  };

  commonVarsFiles = {
    externalDomain = config.sops.secrets.external-domain.path;
  };
in
{
  sops.secrets = {
    nextdns-api-key = {
      key = "nextDNS/common/apiKey";
    };
    nextdns-profile-pro = {
      key = "nextDNS/Pro/profileId";
    };
    nextdns-profile-air = {
      key = "nextDNS/Air/profileId";
    };
    nextdns-profile-mini = {
      key = "nextDNS/Mini/profileId";
    };
    nextdns-profile-phone = {
      key = "nextDNS/Phone/profileId";
    };
    nextdns-profile-asus = {
      key = "nextDNS/Asus/profileId";
    };
    nextdns-profile-lgphone = {
      key = "nextDNS/LgPhone/profileId";
    };
    # nextdns-profile-a3 = {
    #   key = "nextDNS/a3/profileId";
    # };
  };

  local.services.nextdns-mgmt.pro = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-pro.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.air = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-air.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.phone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-phone.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.mini = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-mini.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.asus = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-asus.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.lgphone = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    profileIdFile = config.sops.secrets.nextdns-profile-lgphone.path;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };

  local.services.nextdns-mgmt.a3 = {
    enable = true;
    apiKeyFile = config.sops.secrets.nextdns-api-key.path;
    # No profileId/profileIdFile — module looks up the profile by name "a3"
    # via the NextDNS API, creating it on first run if missing.
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
  };
}
