{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    ../../modules/nixos/tmux-rebuild
    ./tmux-rebuild.nix

    ../../modules/nixos/beszel-agent
    ../../modules/nixos/audiobookshelf-mgmt

    # Base configuration.
    ./configuration.nix

    ./loader.nix

    ./syncthing.nix

    # Enable TPM2 support (required for TPM2 enrollment)
    ./tpm2.nix

    # Uncomment after enrolling TPM2 (see docs/bee.md for instructions)
    ./cryptenroll.nix

    # Security
    ./sudo.nix

    # User configuration
    ./user.nix

    ./ssh.nix

    # Networking
    # FIXME: Did not work yet
    ./networking.nix
    ./dns.nix
    ./http.nix
    ./tailscale.nix
    ./nextdns
    ../../modules/shared/nextdns-mgmt

    # Monitoring
    ./beszel.nix

    # Logging
    ./journald.nix
    ./logrotate.nix

    # Home Automation
    ./services/home-automation

    # Audio
    ./services/audiobookshelf

    # OpenWebUI - restored from K8s
    ./open-webui.nix

    ./power.nix

    ../../nixos/rebuild-diff.nix
  ];
}
