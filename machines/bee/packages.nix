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

    # Network
    nmap

    # Storage
    file
    parted

    # Media
    yt-dlp
    gallery-dl

    ethtool
  ];
}
