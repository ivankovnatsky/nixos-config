{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dust # A more intuitive version of du
    genpass # Password generator
    username # Username generator
    lsof # List open files
    wl-clipboard # Wayland clipboard utilities
    pigz # Parallel gzip compression

    # Secrets management
    sops
    ssh-to-age
    age

    # Hardware monitoring tools
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    smartmontools # Disk health monitoring (smartctl)

    # KDE Wallet integration
    kwalletcli # Provides pinentry-kwallet for GPG integration

    # KDE Remote Desktop Client
    kdePackages.krdc

    sesh
    gum

    nixfmt-rfc-style

    fastfetch

    # Desktop notifications
    libnotify # Provides notify-send command

    ghostty

    nodejs
    gnumake
    delta

    switch-appearance
  ];
}
