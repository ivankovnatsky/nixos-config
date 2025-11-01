{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dust
    ethtool
    file
    gallery-dl
    git
    gnumake
    jq
    lm_sensors
    lsof
    ncurses
    nmap
    parted
    pigz
    rclone
    smartmontools
    tmux
    yt-dlp
  ];
}
