{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    ghostty
    gnumake
    gum
    kdePackages.krdc # KDE Remote Desktop Client
    kwalletcli # Provides pinentry-kwallet for GPG integration
    libnotify # Provides notify-send command
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    lsof # List open files
    nixfmt
    sesh
    smartmontools # Disk health monitoring (smartctl)
    wl-clipboard # Wayland clipboard utilities
  ];
}
