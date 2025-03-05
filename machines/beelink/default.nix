{ pkgs, ... }:

{
  imports = [
    # Base configuration.
    ./configuration.nix

    # Machine specific configuration
    ./syncthing.nix
    ./watchman.nix

    # Uncomment after enrolling TPM2 (see docs/beelink.md for instructions)
    ./cryptenroll.nix

    # System services
    ../../nixos/ssh.nix
  ];

  # Enable TPM2 support (required for TPM2 enrollment)
  security.tpm2.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    tmux
  ];
}
