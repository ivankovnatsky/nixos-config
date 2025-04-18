{ pkgs, ... }:
{
  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Rebuild service
    gnumake
    tmux

    # Monitoring
    lsof
    dust

    # Storage
    file
    parted
  ];
}
