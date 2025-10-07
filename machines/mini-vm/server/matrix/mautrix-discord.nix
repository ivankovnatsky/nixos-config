{ config, pkgs, ... }:
{
  # Use updated module from nixpkgs unstable (not available in nixos-25.05)
  disabledModules = [ "services/matrix/mautrix-discord.nix" ];
  imports = [ ../../../../modules/nixos/mautrix-discord ];

  # https://docs.mau.fi/bridges/go/discord/index.html
  # Using local module from nixpkgs unstable (not nixos-25.05)
  local.services.mautrix-discord = {
    enable = true;

    # Use package from nixpkgs-unstable-nixos overlay (has binary cache)
    package = pkgs.nixpkgs-unstable-nixos.mautrix-discord;

    # Automatically register the bridge with Synapse
    # This adds the registration file to Synapse's app_service_config_files
    # WARNING: When enabled, if this bridge fails to generate its registration file,
    # Synapse will fail to start, breaking ALL bridges (including Telegram, WhatsApp).
    registerToSynapse = true;

    settings = {
      homeserver = {
        address = "http://127.0.0.1:8008";
        domain = "matrix-mini.${config.secrets.externalDomain}";
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
          "@${config.secrets.matrix.username}:matrix-mini.${config.secrets.externalDomain}" = "admin";
          "*" = "relay";
        };
      };
    };
  };
}
