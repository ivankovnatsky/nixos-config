{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dust  # A more intuitive version of du
    lsof  # List open files
    wl-clipboard  # Wayland clipboard utilities

    # Hardware monitoring tools
    lm_sensors  # Provides the 'sensors' command for monitoring temperatures
    nixpkgs-master.claude-code

    sesh
    gum

    nixfmt-rfc-style

    fastfetch
    
    # Desktop notifications
    libnotify  # Provides notify-send command

    ghostty
  ];
}
