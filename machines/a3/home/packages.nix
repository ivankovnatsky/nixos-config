{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dust  # A more intuitive version of du
    lsof  # List open files
    wl-clipboard  # Wayland clipboard utilities
    pigz  # Parallel gzip compression

    # Hardware monitoring tools
    lm_sensors  # Provides the 'sensors' command for monitoring temperatures


    # KDE Wallet integration
    kwalletcli  # Provides pinentry-kwallet for GPG integration

    sesh
    gum

    nixfmt-rfc-style

    fastfetch

    # Desktop notifications
    libnotify  # Provides notify-send command

    ghostty

    nodejs
  ];
}
