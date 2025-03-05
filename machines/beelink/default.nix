{ pkgs, ... }:

{
  imports = [
    # Base and hardware configuration.
    ./configuration.nix
    ./hardware-configuration.nix

    # Machine specific configuration
    ./syncthing.nix
    
    # Uncomment after enrolling TPM2 (see docs/beelink.md for instructions)
    # ./cryptenroll.nix

    # System services
    ../../nixos/ssh.nix
  ];
  
  # Additional system packages
  environment.systemPackages = with pkgs; [
    tmux
  ];
}
