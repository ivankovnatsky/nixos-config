{ pkgs, ... }:

{
  home.packages = with pkgs; [
    age # Secrets management
    backup-home # Home directory backup tool
    delta
    dotfiles
    dust # A more intuitive version of du
    fastfetch
    genpass # Password generator
    gh-notifications
    ghostty
    git-message
    gnumake
    gum
    jq
    kdePackages.krdc # KDE Remote Desktop Client
    kwalletcli # Provides pinentry-kwallet for GPG integration
    libnotify # Provides notify-send command
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    lsof # List open files
    nixfmt
    nodejs
    pigz # Parallel gzip compression
    poweroff
    sesh
    settings
    smartmontools # Disk health monitoring (smartctl)
    sops # Secrets management
    ssh-to-age # Secrets management
    syncthing-mgmt # Syncthing management CLI
    uptime-kuma-mgmt
    username # Username generator
    wl-clipboard # Wayland clipboard utilities
  ];
}
