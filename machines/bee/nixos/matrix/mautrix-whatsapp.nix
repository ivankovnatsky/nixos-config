{ config, pkgs, ... }:
{
  # Use updated module from nixpkgs master for new config format
  disabledModules = [ "services/matrix/mautrix-whatsapp.nix" ];

  # Sops secrets for Matrix bridge
  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  sops.secrets.matrix-username = {
    key = "matrix/username";
  };

  # Create environment file from sops secrets for mautrix-whatsapp
  sops.templates."mautrix-whatsapp.env".content = ''
    EXTERNAL_DOMAIN=${config.sops.placeholder."external-domain"}
    MATRIX_USERNAME=${config.sops.placeholder."matrix-username"}
  '';

  # https://docs.mau.fi/bridges/go/whatsapp/index.html
  # Using local module from nixpkgs master (not nixos-25.05) for new config format
  local.services.mautrix-whatsapp = {
    enable = true;

    package = pkgs.mautrix-whatsapp.overrideAttrs (old: {
      version = "0.12.5-unstable-2025-10-04";
      src = pkgs.fetchFromGitHub {
        owner = "mautrix";
        repo = "whatsapp";
        rev = "425556d0fa511bd2c898469f55de10c98cd912f5";
        hash = "sha256-fzOPUdTM7mRhKBuGrGMuX2bokBpn4KdVclXjrAT4koM=";
      };
      vendorHash = "sha256-t3rvnKuuZe8j3blyQTANMoIdTc2n4XXri6qfjIgFR0A=";
    });

    # Automatically register the bridge with Synapse
    # This adds the registration file to Synapse's app_service_config_files
    # WARNING: When enabled, if this bridge fails to generate its registration file,
    # Synapse will fail to start, breaking ALL bridges (including Telegram).
    # The bridge is now working with the new config format, safe to enable.
    registerToSynapse = true;

    # Load secrets from sops-generated environment file
    environmentFile = config.sops.templates."mautrix-whatsapp.env".path;

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        # Using environment variable from sops template
        domain = "matrix.$EXTERNAL_DOMAIN";
      };

      appservice = {
        address = "http://127.0.0.1:29318";
        # Intentionally localhost only - Synapse and bridge run on same machine
        # More secure (not exposed on network), only Synapse needs to connect
        hostname = "127.0.0.1";
        port = 29318;
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
