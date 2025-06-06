{ pkgs, ... }:
{
  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Rebuild service
    gnumake
    tmux

    # Sync
    rclone

    # Monitoring
    lsof
    dust

    # Storage
    file
    parted

    vim

    # Media
    yt-dlp
    gallery-dl
  ];
}
