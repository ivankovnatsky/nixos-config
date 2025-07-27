{ pkgs, ... }:

{
  # System packages for a3
  environment.systemPackages = with pkgs; [
    dust  # A more intuitive version of du
    lsof  # List open files
    wl-clipboard  # Wayland clipboard utilities
  ];
}
