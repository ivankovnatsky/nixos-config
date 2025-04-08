{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    ../../modules/nixos/tmux-rebuild
    ./tmux-rebuild.nix

    # Base configuration.
    ./configuration.nix

    ./loader.nix

    ./syncthing.nix

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
    # ./networking.nix
    ./dns.nix
    ./http.nix

    # Monitoring
    ./logging.nix
    ./netdata.nix

    # Logging
    ./journald.nix
    ./logrotate.nix

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./plex.nix
    ./radarr.nix
    ./sonarr.nix
    ./transmission.nix
    ./prowlarr.nix

    # Audio
    ./audiobookshelf.nix

    # Constantly using 2 CPU Cores, disabling for now
    # ./flaresolverr.nix

    ./home-assistant.nix

    # Storage
    ./storage.nix

    ./miniserve.nix
  ];
}
