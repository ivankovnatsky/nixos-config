{ pkgs, ... }:

{
  imports = [
    # Base and hardware configuration.
    ./configuration.nix
    ./hardware-configuration.nix

    # Machine specific configuration
    ./syncthing.nix

    # System services
    ../../nixos/ssh.nix
  ];
  
  # Additional system packages
  environment.systemPackages = with pkgs; [
    tmux
  ];
}
