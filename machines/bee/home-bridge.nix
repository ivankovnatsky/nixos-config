{ config, pkgs, ... }:
let
  homebridgePackageJson = pkgs.writeText "package.json" (
    builtins.toJSON {
      private = true;
      description = "This file keeps track of which plugins should be installed.";
      dependencies = {
        "homebridge" = "^1.11.0";
        "homebridge-keylights" = "1.3.2";
        "homebridge-z2m" = "^1.9.3";
      };
    }
  );

  homebridgeConfig = pkgs.writeText "config.json" (
    builtins.toJSON {
      bridge = {
        name = "Homebridge 3E57";
        username = "0E:D5:58:2D:36:57";
        port = 51318;
        pin = "398-00-752";
        advertiser = "bonjour-hap";
      };
      accessories = [ ];
      platforms = [
        {
          name = "Config";
          port = 8581;
          platform = "config";
        }
        {
          name = "Elgato Key Lights";
          pollingRate = 1000;
          powerOnBehavior = 1;
          powerOnBrightness = 20;
          powerOnTemperature = 200;
          switchOnDurationMs = 100;
          switchOffDurationMs = 300;
          colorChangeDurationMs = 100;
          useIP = true;
          platform = "ElgatoKeyLights";
        }
        {
          platform = "zigbee2mqtt";
          name = "Zigbee2MQTT";
          mqtt = {
            base_topic = "zigbee2mqtt";
            server = "mqtt://${config.flags.beeIp}:1883";
          };
        }
      ];
    }
  );
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      homebridge = {
        volumes = [
          "/var/lib/homebridge:/homebridge"
        ];
        environment = {
          TZ = config.secrets.time_zone;
        };
        image = "homebridge/homebridge:2025-07-12";
        extraOptions = [
          # Network access for HomeKit and device discovery
          "--network=host"
          # Logging options
          "--log-opt=max-size=10m"
          "--log-opt=max-file=1"
        ];
        # Logging configuration
        log-driver = "json-file";
      };
    };
  };

  # Open firewall for Homebridge
  networking.firewall.allowedTCPPorts = [
    8581 # Homebridge web UI
    51318 # HomeKit bridge port (actual port from logs)
  ];

  # Copy package.json and config.json to writable location before starting container
  systemd.services.homebridge-config-setup = {
    description = "Copy Homebridge configuration files to writable location";
    wantedBy = [ "docker-homebridge.service" ];
    before = [ "docker-homebridge.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Ensure directory exists
      mkdir -p /var/lib/homebridge
      # Always overwrite with our declarative files
      cp ${homebridgePackageJson} /var/lib/homebridge/package.json
      cp ${homebridgeConfig} /var/lib/homebridge/config.json
      chmod 644 /var/lib/homebridge/package.json
      chmod 644 /var/lib/homebridge/config.json
      echo "Copied declarative package.json and config.json"
    '';
  };

  # Create homebridge data directory
  systemd.tmpfiles.rules = [
    "d /var/lib/homebridge 0755 root root -"
  ];
}
