{ config, pkgs, ... }:
let
  # Generate basic configuration.yaml for the container
  format = pkgs.formats.yaml { };
  configuration = format.generate "configuration.yaml" {
    # Includes dependencies for a basic setup
    # https://www.home-assistant.io/integrations/default_config/
    default_config = { };
    
    # Database configuration
    recorder = {
      db_url = "postgresql://hass@/hass";
    };
    
    # Set location information
    homeassistant = {
      name = "Home";
      inherit (config.secrets) latitude longitude time_zone;
      elevation = 0;
      unit_system = "metric";
    };
    
    # Basic HTTP configuration
    http = {
      server_host = "0.0.0.0";
      server_port = 8123;
      # Enable proxy support
      use_x_forwarded_for = true;
      # Trust the Caddy proxy server and local network
      trusted_proxies = [
        "127.0.0.1"
        "::1"
        "192.168.50.0/24"
      ];
    };
    
    # MQTT configuration for Zigbee2MQTT integration
    # Note: MQTT is now configured via UI in newer versions
    # This empty config allows the integration to be set up manually
    mqtt = { };
  };
in
{
  # Create hass system user
  users.users.hass = {
    isSystemUser = true;
    group = "hass";
    extraGroups = [ "postgres" ];
    home = "/var/lib/hass";
  };
  users.groups.hass = {};

  # Container-based Home Assistant
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      homeassistant = {
        volumes = [
          "/var/lib/hass:/config"
          "${configuration}:/config/configuration.yaml:ro"
          "/run/dbus:/run/dbus:ro"
          "/run/postgresql:/run/postgresql:ro"
        ];
        environment = {
          TZ = config.secrets.time_zone;
        };
        image = "ghcr.io/home-assistant/home-assistant:2024.12";
        extraOptions = [
          # Access to Zigbee adapter
          "--device=/dev/zigbee_adapter:/dev/zigbee_adapter"
          # Network access for integrations
          "--network=host"
          # Privileged access for hardware integrations
          "--privileged"
        ];
      };
    };
  };

  # Open firewall for Home Assistant
  networking.firewall.allowedTCPPorts = [ 8123 ];
}
