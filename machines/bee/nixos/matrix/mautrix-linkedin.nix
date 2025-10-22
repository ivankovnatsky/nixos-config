{ config, ... }:
{
  # Allow insecure olm package required by mautrix-linkedin for E2BE
  # olm is deprecated upstream but still used by mautrix bridges
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  local.services.mautrix-linkedin = {
    enable = true;

    registerToSynapse = true;

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        domain = "matrix.${config.secrets.externalDomain}";
      };

      appservice = {
        address = "http://127.0.0.1:29321";
        hostname = "127.0.0.1";
        port = 29321;
      };

      bridge = {
        permissions = {
          "@${config.secrets.matrix.username}:matrix.${config.secrets.externalDomain}" = "admin";
          "*" = "relay";
        };
      };
    };
  };
}
