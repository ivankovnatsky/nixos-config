{ config, pkgs, ... }:
{
  # Use updated module from nixpkgs unstable (not available in nixos-25.05)
  disabledModules = [ "services/matrix/mautrix-discord.nix" ];

  # Sops secrets for Matrix bridge
  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  sops.secrets.matrix-username = {
    key = "matrix/username";
  };

  # Create environment file from sops secrets for mautrix-discord
  sops.templates."mautrix-discord.env".content = ''
    EXTERNAL_DOMAIN=${config.sops.placeholder."external-domain"}
    MATRIX_USERNAME=${config.sops.placeholder."matrix-username"}
  '';

  # https://docs.mau.fi/bridges/go/discord/index.html
  # Using local module from nixpkgs unstable (not nixos-25.05)
  local.services.mautrix-discord = {
    enable = true;

    # Use package from nixpkgs-unstable-nixos overlay (has binary cache)
    package = pkgs.nixpkgs-nixos-unstable.mautrix-discord;

    # Automatically register the bridge with Synapse
    # This adds the registration file to Synapse's app_service_config_files
    # WARNING: When enabled, if this bridge fails to generate its registration file,
    # Synapse will fail to start, breaking ALL bridges (including Telegram, WhatsApp).
    registerToSynapse = true;

    # Load secrets from sops-generated environment file
    environmentFile = config.sops.templates."mautrix-discord.env".path;

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        # Using environment variable from sops template
        domain = "matrix.$EXTERNAL_DOMAIN";
      };

      appservice = {
        address = "http://127.0.0.1:29319";
        # Intentionally localhost only - Synapse and bridge run on same machine
        # More secure (not exposed on network), only Synapse needs to connect
        hostname = "127.0.0.1";
        port = 29319;

        # Discord bridge requires database config under appservice (unlike Telegram/WhatsApp)
        database = {
          type = "sqlite3";
          uri = "file:/var/lib/mautrix-discord/mautrix-discord.db?_txlock=immediate";
        };
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
