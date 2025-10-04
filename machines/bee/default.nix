{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    ../../modules/nixos/tmux-rebuild
    ./server/tmux-rebuild.nix

    # Base configuration.
    ./server/configuration.nix
    ./server/user.nix

    ./server/loader.nix

    ./server/syncthing.nix

    ./server/packages.nix

    # Enable TPM2 support (required for TPM2 enrollment)
    ./server/tpm2.nix

    # Uncomment after enrolling TPM2 (see docs/bee.md for instructions)
    ./server/cryptenroll.nix

    # Security
    ./server/sudo.nix

    ./server/ssh.nix

    # Networking
    # FIXME: Did not work yet
    ./server/networking.nix
    ./server/dns.nix
    ./server/doh.nix
    ./server/http.nix
    ./server/tailscale.nix
    ./server/nextdns
    ../../modules/shared/nextdns-mgmt

    # Monitoring
    ./server/logging.nix
    # ./server/netdata.nix

    # Logging
    ./server/journald.nix
    ./server/logrotate.nix

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./server/plex.nix
    ./server/radarr.nix
    ./server/sonarr.nix
    ./server/transmission.nix
    ./server/prowlarr.nix

    ./server/stash

    # Audio
    ./server/audiobookshelf.nix
    ./server/jellyfin.nix

    # Samba
    ./server/samba.nix

    # Constantly using 2 CPU Cores, disabling for now
    # ./server/flaresolverr.nix

    # Home Automation
    ./server/home-assistant.nix
    # ./server/home-assistant-container.nix
    ./server/mosquitto.nix
    ./server/zigbee2mqtt.nix
    ./server/matter-server.nix
    ./server/bluetooth.nix

    ./server/home-bridge.nix
    ./server/matter-bridge.nix

    # Matrix
    ./server/matrix

    # Storage
    ./server/storage.nix

    ./server/miniserve.nix

    ./server/open-webui.nix

    ./server/power.nix

    ../../nixos/rebuild-diff.nix
  ];
}
