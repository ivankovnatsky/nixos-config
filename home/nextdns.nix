{ config, ... }:

let
  commonVars = {
    inherit (config.inventory)
      miniIp
      miniWifiIp
      a3Ip
      a3WifiIp
      ;
  };

  commonVarsFiles = {
    externalDomain = config.sops.secrets.external-domain.path;
  };

  commonProfile = {
    enable = true;
    profileFile = ../templates/nextdns-profile.json;
    vars = commonVars;
    varsFiles = commonVarsFiles;
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

  local.services.nextdns-mgmt = {
    pro = commonProfile;
    air = commonProfile;
    phone = commonProfile;
    mini = commonProfile;
    asus = commonProfile;
    lgphone = commonProfile;
    # a3 has no nextdns-profile-a3 sops secret; the CLI falls back to looking
    # up the profile by name (creating it on first run if missing).
    a3 = commonProfile;
  };
}
