{ pkgs, ... }:

{
  home.packages = with pkgs; [
    backup-home # Home directory backup tool
    dust # A more intuitive version of du
    genpass # Password generator
    username # Username generator
    lsof # List open files
    wl-clipboard # Wayland clipboard utilities
    pigz # Parallel gzip compression

    # Syncthing management CLI
    syncthing-mgmt
    uptime-kuma-mgmt

    # Hardware monitoring tools
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    smartmontools # Disk health monitoring (smartctl)

    # Secrets management
    age
    sops
    ssh-to-age

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
    git-message

    nodejs
    gnumake
    delta

    open-gh-notifications-py

    settings
  ];
}
