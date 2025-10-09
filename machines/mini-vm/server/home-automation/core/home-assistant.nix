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
            universal-silabs-flasher # Required for ZHA with Silicon Labs adapters
            python-otbr-api # Thread Border Router API
            govee-ble # Govee Bluetooth Low Energy devices
            inkbird-ble # Inkbird Bluetooth Low Energy devices
            xiaomi-ble # Xiaomi Bluetooth Low Energy devices
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
      "zha" # Zigbee Home Automation
      "homeassistant_hardware" # Required for ZHA hardware support
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
          "0.0.0.0"
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
          "192.168.139.0/24" # OrbStack network (mini's Caddy)
        ];
      };

      # MQTT Configuration for zigbee2mqtt
      # Mosquitto MQTT broker runs on bee (192.168.50.3:1883).
      # Zigbee2MQTT on bee publishes sensor data to the broker.
      #
      # Manual reconfiguration required:
      # 1. Go to Settings -> Devices & Services -> Integrations
      # 2. Find MQTT integration -> Click three dots -> Reconfigure
      # 3. Change broker to 192.168.50.3 (bee's IP)
      # 4. Port: 1883
      # 5. Save and verify Zigbee2MQTT bridge reconnects
      #
      # See: https://github.com/home-assistant/core/issues/114643
      mqtt = { };

      # Matter Integration Configuration
      # After restoring backup, the Matter integration pointed to localhost:5580
      # (which was correct on bee). After migration to mini-vm, Matter Server
      # remains on bee (hardware dependency - USB Thread Border Router).
      #
      # Manual reconfiguration required:
      # 1. Remove old Matter integration from Settings -> Devices & Services
      # 2. Add new Matter integration
      # 3. Configure Matter Server URL: ws://192.168.50.3:5580/ws
      #    (connects to Matter Server running on bee)
      # 4. Verify Eve Energy devices reconnect automatically
    };
    openFirewall = true;
  };

  services.postgresql = {
    enable = true;
    # authentication = ''
    #   local hass hass ident map=ha
    # '';
    # identMap = ''
    #   ha root hass
    # '';
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

  # Fix blueprint directory permissions for backup restore
  systemd.tmpfiles.rules = [
    "d /var/lib/hass/blueprints 0700 hass hass -"
    "d /var/lib/hass/blueprints/automation 0700 hass hass -"
    "d /var/lib/hass/blueprints/script 0700 hass hass -"
    "Z /var/lib/hass/blueprints/automation/homeassistant 0755 hass hass -"
    "Z /var/lib/hass/blueprints/script/homeassistant 0755 hass hass -"
  ];
}
