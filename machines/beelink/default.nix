{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    # Base configuration.
    ./configuration.nix

    ./loader.nix

    ./syncthing.nix

    ./packages.nix

    # Enable TPM2 support (required for TPM2 enrollment)
    ./tpm2.nix

    # Uncomment after enrolling TPM2 (see docs/beelink.md for instructions)
    ./cryptenroll.nix

    # Security
    ./sudo.nix

    ./ssh.nix
    ./tmux-nixos-rebuild.nix

    # Networking
    ./dns.nix
    ./http-routing.nix

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
  ];
}
