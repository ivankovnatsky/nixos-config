{
  imports = [
    ../../../modules/flags
    ../../../modules/nixos/rebuild-daemon
    ../../../modules/nixos/syncthing-mgmt
    ../../../nixos/rebuild-diff.nix
    ../../../system/nix.nix
    ../../../system/scripts
    ./configuration.nix # Base configuration.
    ./cryptenroll.nix # Uncomment after enrolling TPM2 (see docs/bee.md for instructions)
    ./journald.nix # Logging
    ./loader.nix
    ./packages.nix
    ./power.nix
    ./rebuild-daemon.nix
    ./sops.nix # Shared sops secrets
    ./ssh.nix
    ./sudo.nix # Security
    ./syncthing-mgmt.nix
    ./syncthing.nix
    ./tailscale.nix
    ./tpm2.nix # Enable TPM2 support (required for TPM2 enrollment)
    ./user.nix # User configuration
  ];
}
