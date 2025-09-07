{ pkgs, ... }:
{
  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Rebuild service
    gnumake
    tmux
    git
    git-crypt

    # Sync
    rclone

    # Monitoring
    lsof
    dust
    
    # Hardware sensors
    lm_sensors
    
    # Terminal utilities
    ncurses

    # Network
    nmap

    # Storage
    file
    parted

    # Media
    yt-dlp
    gallery-dl

    # Utils
    jq

    ethtool
  ];
}
