{ pkgs, ... }:
{
  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Rebuild service
    tmux

    # Monitoring
    lsof

    # Storage
    file
    parted
  ];
}
