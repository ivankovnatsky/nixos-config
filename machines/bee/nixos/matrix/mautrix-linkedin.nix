{ config, ... }:
{
  # Allow insecure olm package required by mautrix-linkedin for E2BE
  # olm is deprecated upstream but still used by mautrix bridges
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  # Sops secrets for Matrix bridge
  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  sops.secrets.matrix-username = {
    key = "matrix/username";
  };

  # Create environment file from sops secrets for mautrix-linkedin
  sops.templates."mautrix-linkedin.env".content = ''
    EXTERNAL_DOMAIN=${config.sops.placeholder."external-domain"}
    MATRIX_USERNAME=${config.sops.placeholder."matrix-username"}
  '';

  local.services.mautrix-linkedin = {
    enable = true;

    registerToSynapse = true;

    # Load secrets from sops-generated environment file
    environmentFile = config.sops.templates."mautrix-linkedin.env".path;

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        # Using environment variable from sops template
        domain = "matrix.$EXTERNAL_DOMAIN";
      };

      appservice = {
        address = "http://127.0.0.1:29321";
        hostname = "127.0.0.1";
        port = 29321;
      };

      bridge = {
        permissions = {
          # Using environment variables from sops template
          "@$MATRIX_USERNAME:matrix.$EXTERNAL_DOMAIN" = "admin";
          "*" = "relay";
        };
      };
    };
  };
}
