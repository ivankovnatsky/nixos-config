{
  imports = [
    ../../../modules/secrets
    ../../../modules/flags

    ../../../modules/nixos/tmux-rebuild
    ./tmux-rebuild.nix

    ../../../modules/nixos/beszel-agent

    # Base configuration.
    ./configuration.nix
    ./user.nix

    ./loader.nix

    ./syncthing.nix
    ./data.nix

    ./packages.nix

    # Enable TPM2 support (required for TPM2 enrollment)
    ./tpm2.nix

    # Uncomment after enrolling TPM2 (see docs/bee.md for instructions)
    ./cryptenroll.nix

    # Security
    ./sudo.nix

    ./ssh.nix

    # Networking
    # FIXME: Did not work yet
    ./networking.nix
    ./dns.nix
    ./doh.nix
    ./http.nix
    ./tailscale.nix
    ./nextdns
    ../../../modules/shared/nextdns-mgmt

    # Monitoring
    ./logging.nix
    # ./netdata.nix
    ./beszel.nix

    # Logging
    ./journald.nix
    ./logrotate.nix

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./plex.nix
    ./services/radarr.nix
    ./services/sonarr.nix
    ./services/transmission.nix
    ./services/prowlarr.nix

    # Audio
    ./services/audiobookshelf.nix

    # Samba
    ./samba.nix

    # Constantly using 2 CPU Cores, disabling for now
    # ./flaresolverr.nix

    # Home Automation
    ./services/home-assistant.nix
    # ./home-assistant-container.nix
    ./services/mosquitto.nix
    ./services/zigbee2mqtt.nix
    ./services/matter-server.nix
    ./bluetooth.nix

    ./services/home-bridge.nix
    ./services/matter-bridge.nix

    # Matrix
    ./services/matrix

    # Storage
    ./storage.nix

    ./miniserve.nix

    ./power.nix

    ../../../nixos/rebuild-diff.nix
  ];
}
