{ config, pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    package =
      (pkgs.home-assistant.override {
        extraPackages =
          py: with py; [
            psycopg2
            getmac
            pyatv
            gtts # Google Text-to-Speech
            bluetooth-auto-recovery # Bluetooth support
            bleak # Bluetooth Low Energy support
            zeroconf
            ifaddr # Better interface detection
          ];
      }).overrideAttrs
        (oldAttrs: {
          doInstallCheck = false;
        });
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
      "mqtt" # Required for zigbee2mqtt integration
      "bluetooth" # Bluetooth integration
      "zeroconf" # Add zeroconf component explicitly
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      recorder.db_url = "postgresql://@/hass";

      # Set location information in the correct format
      homeassistant = {
        name = "Home";
        inherit (config.secrets) latitude longitude time_zone;
        elevation = 0;
        unit_system = "metric";
      };

      # Basic HTTP configuration
      http = {
        server_host = [
          "127.0.0.1"
          config.flags.beeIp
        ];
        server_port = 8123;
        # Enable proxy support
        use_x_forwarded_for = true;
        # Trust the Caddy proxy server
        trusted_proxies = [
          "127.0.0.1"
          "::1"
          "${config.flags.beeIp}"
          "${config.flags.miniIp}"
        ];
      };

      # MQTT Configuration for zigbee2mqtt
      # Configured in UI, need to manually add integration:
      # https://github.com/home-assistant/core/issues/114643
      mqtt = { };
    };
    openFirewall = true;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };

  # Ensure the Home Assistant service starts after PostgreSQL is fully up
  systemd.services.home-assistant = {
    after = [
      "postgresql.service"
      "network-online.target"
    ];
    requires = [ 
      "postgresql.service" 
      "network-online.target"
    ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE CAP_NET_RAW"; # Add network capabilities
      Environment = "PYTHONUNBUFFERED=1";
    };
  };
}
