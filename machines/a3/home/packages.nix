{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rocmPackages.rocm-smi
    amdgpu_top
    fastfetch
    ghq-cd
    gnumake
    gum
    kdePackages.krdc # KDE Remote Desktop Client
    pinentry-qt # Qt pinentry for GPG
    libnotify # Provides notify-send command
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    lsof # List open files
    nixfmt
    smartmontools # Disk health monitoring (smartctl)
    wl-clipboard # Wayland clipboard utilities
    wally-cli
  ];
}
