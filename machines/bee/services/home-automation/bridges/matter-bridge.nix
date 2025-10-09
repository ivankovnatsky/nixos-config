{ config, pkgs, ... }:
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      matterbridge = {
        volumes = [
          "/var/lib/matterbridge/plugins:/root/Matterbridge"
          "/var/lib/matterbridge/storage:/root/.matterbridge"
        ];
        environment = {
          TZ = config.secrets.time_zone;
        };
        image = "luligu/matterbridge:3.1.4";
        extraOptions = [
          # Network access for Matter mdns
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

  # Open firewall for Matterbridge
  networking.firewall = {
    allowedTCPPorts = [
      8283 # Matterbridge web UI and health check endpoint
      5540 # Matter commissioning port (as shown in UI)
    ];
    allowedUDPPorts = [
      5353 # mDNS/Bonjour for device discovery
      5540 # Matter commissioning (UDP)
    ];
  };

  # Create matterbridge data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/matterbridge 0755 root root -"
    "d /var/lib/matterbridge/plugins 0755 root root -"
    "d /var/lib/matterbridge/storage 0755 root root -"
  ];
}
