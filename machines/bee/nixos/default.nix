{
  imports = [
    ../../../modules/flags
    ../../../modules/nixos/audiobookshelf-mgmt
    ../../../modules/nixos/beszel-agent
    ../../../modules/nixos/mautrix-discord
    ../../../modules/nixos/mautrix-linkedin
    ../../../modules/nixos/mautrix-whatsapp
    ../../../modules/nixos/rebuild-daemon
    ../../../modules/nixos/syncthing-mgmt
    ../../../modules/nixos/tmux-rebuild
    ../../../modules/shared/arr-mgmt
    ../../../modules/shared/nextdns-mgmt
    ../../../nixos/rebuild-diff.nix
    ../../../system/documentation.nix # Disable documentation to avoid mautrix module mismatch issues
    ../../../system/nix.nix
    ../../../system/scripts
    ./audiobookshelf
    ./beszel.nix # Monitoring
    ./configuration.nix # Base configuration.
    ./cryptenroll.nix # Uncomment after enrolling TPM2 (see docs/bee.md for instructions)
    ./dns.nix
    ./doh.nix
    ./home-automation
    ./http.nix
    ./journald.nix # Logging
    ./loader.nix
    ./logrotate.nix
    ./matrix
    ./networking.nix # FIXME: Did not work yet
    ./nextdns
    ./open-webui.nix
    ./packages.nix
    ./power.nix
    ./rebuild-daemon.nix
    ./sops.nix # Shared sops secrets
    ./ssh.nix
    ./sudo.nix # Security
    ./syncthing-mgmt.nix
    ./syncthing.nix
    ./tailscale.nix
    ./tmux-rebuild.nix
    ./tpm2.nix # Enable TPM2 support (required for TPM2 enrollment)
    ./user.nix # User configuration
  ];
}
