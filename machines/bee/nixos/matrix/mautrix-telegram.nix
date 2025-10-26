{ config, ... }:
{
  # Allow insecure olm package required by mautrix-telegram for E2BE
  # olm is deprecated upstream but still used by mautrix-telegram
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

  sops.secrets.telegram-api-id = {
    key = "telegram/apiId";
  };

  sops.secrets.telegram-api-hash = {
    key = "telegram/apiHash";
  };

  # Create environment file from sops secrets for mautrix-telegram
  sops.templates."mautrix-telegram.env".content = ''
    MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder."telegram-api-id"}
    MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder."telegram-api-hash"}
    EXTERNAL_DOMAIN=${config.sops.placeholder."external-domain"}
    MATRIX_USERNAME=${config.sops.placeholder."matrix-username"}
  '';

  # NOTE: If changing appservice settings (port, etc), delete the data dir to regenerate:
  #   sudo systemctl stop mautrix-telegram.service matrix-synapse.service
  #   sudo rm -rf /var/lib/mautrix-telegram
  # The NixOS module preserves existing config files and only generates them on first run.
  services.mautrix-telegram = {
    enable = true;

    # Automatically register the bridge with Synapse
    # This adds the registration file to Synapse's app_service_config_files
    # WARNING: When enabled, if this bridge fails to generate its registration file,
    # Synapse will fail to start, breaking ALL bridges.
    registerToSynapse = true;

    # Load Telegram API credentials from sops-generated environment file
    environmentFile = config.sops.templates."mautrix-telegram.env".path;

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        # Using environment variable from sops template
        domain = "matrix.$EXTERNAL_DOMAIN";
      };

      appservice = {
        address = "http://127.0.0.1:29317";
        # Intentionally localhost only - Synapse and bridge run on same machine
        # More secure (not exposed on network), only Synapse needs to connect
        hostname = "127.0.0.1";
        port = 29317;
      };

      bridge = {
        permissions = {
          # Using environment variables from sops template
          "@$MATRIX_USERNAME:matrix.$EXTERNAL_DOMAIN" = "admin";
          "*" = "relaybot";
        };
      };

      telegram = {
        # Telegram API credentials loaded from environmentFile
        # The module will substitute $MAUTRIX_TELEGRAM_TELEGRAM_API_ID and $MAUTRIX_TELEGRAM_TELEGRAM_API_HASH
        # from the environment file at runtime
      };
    };
  };
}
