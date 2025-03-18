{ username, ... }:
{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    ../../modules/nixos/tmux-rebuild

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

    # Networking
    # FIXME: Did not work yet
    # ./networking.nix
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

  # Configure the tmux rebuild service
  services.tmuxRebuild = {
    enable = true;
    username = username; # Use the username variable from the flake
    nixosConfigPath = "/home/${username}/Sources/github.com/ivankovnatsky/nixos-config"; # Use the username variable in the path
  };
}
