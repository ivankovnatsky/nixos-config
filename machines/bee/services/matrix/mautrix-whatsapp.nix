{ config, pkgs, ... }:
{
  # Use updated module from nixpkgs master for new config format
  disabledModules = [ "services/matrix/mautrix-whatsapp.nix" ];
  imports = [ ../../../../modules/nixos/mautrix-whatsapp ];

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

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        domain = "matrix.${config.secrets.externalDomain}";
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
          "@${config.secrets.matrix.username}:matrix.${config.secrets.externalDomain}" = "admin";
          "*" = "relay";
        };
      };
    };
  };
}
