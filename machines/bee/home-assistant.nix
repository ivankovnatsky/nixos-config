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
            # pyserial # Required for serial communication
            # zigpy # Base Zigbee support
            # zigpy-znp # Required for Silicon Labs (EFR32) based coordinators like SLZB-07
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
      "zha" # Zigbee Home Automation integration
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      recorder.db_url = "postgresql://@/hass";

      # Set location information in the correct format
      homeassistant = {
        name = "Home";
        latitude = config.secrets.latitude;
        longitude = config.secrets.longitude;
        elevation = 0;
        unit_system = "metric";
        time_zone = config.secrets.timezone;
      };

      # Basic HTTP configuration
      http = {
        # Listen on all interfaces for proxy access
        server_host = "0.0.0.0";
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

      # Declarative ZHA (Zigbee Home Automation) configuration
      zha = {
        usb_path = "/dev/ttyUSB0";
        database_path = "/var/lib/hass/zigbee.db";
        radio_type = "znp";
      };
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
  systemd.services.home-assistant.after = [ "postgresql.service" ];
  systemd.services.home-assistant.requires = [ "postgresql.service" ];
}
