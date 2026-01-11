{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        markitdown
      ]
    ))
    age # Secrets management
    backup-home # Home directory backup tool
    delta
    dust # A more intuitive version of du
    fastfetch
    genpass # Password generator
    ghostty
    git-message
    gnumake
    gum
    kdePackages.krdc # KDE Remote Desktop Client
    kwalletcli # KDE Wallet integration # Provides pinentry-kwallet for GPG integration
    libnotify # Desktop notifications # Provides notify-send command
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    lsof # List open files
    nixfmt-rfc-style
    nodejs
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    open-gh-notifications-py
    pigz # Parallel gzip compression
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
