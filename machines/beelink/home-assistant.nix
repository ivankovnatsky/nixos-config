{ config, pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    package = (pkgs.home-assistant.override {
      extraPackages = py: with py; [ 
        psycopg2 
        getmac
        pyatv
      ];
    }).overrideAttrs (oldAttrs: {
      doInstallCheck = false;
    });
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
      recorder.db_url = "postgresql://@/hass";
      
      # Set location information
      latitude = config.secrets.latitude;
      longitude = config.secrets.longitude;
      
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
          "${config.flags.beelinkIp}"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };
}
