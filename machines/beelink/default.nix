{ pkgs, ... }:

{
  imports = [
    # Base configuration.
    ./configuration.nix

    # Machine specific configuration
    ./syncthing.nix
    ./ssh.nix
    ./watchman.nix
    # ./netdata.nix

    # Uncomment after enrolling TPM2 (see docs/beelink.md for instructions)
    ./cryptenroll.nix
  ];

  # Enable TPM2 support (required for TPM2 enrollment)
  security.tpm2.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    btop
    tmux
  ];
}
