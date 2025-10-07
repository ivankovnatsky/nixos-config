{ config, ... }:
{
  # Allow insecure olm package required by mautrix-telegram for E2BE
  # olm is deprecated upstream but still used by mautrix-telegram
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

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

    settings = {
      homeserver = {
        address = "http://${config.flags.beeIp}:8008";
        domain = "matrix.${config.secrets.externalDomain}";
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
          "@${config.secrets.matrix.username}:matrix.${config.secrets.externalDomain}" = "admin";
          "*" = "relaybot";
        };
      };

      telegram = {
        api_id = config.secrets.telegram.apiId;
        api_hash = config.secrets.telegram.apiHash;
      };
    };
  };
}
