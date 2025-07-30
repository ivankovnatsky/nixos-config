{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dust  # A more intuitive version of du
    lsof  # List open files
    wl-clipboard  # Wayland clipboard utilities

    # Add Wayland flags to Windsurf to fix scaling issues
    # (windsurf.override {
    #   # Use commandLineArgs to add Wayland flags
    #   commandLineArgs = [
    #     "--ozone-platform=wayland"
    #   ];
    # })
    nixpkgs-master.windsurf

    # Hardware monitoring tools
    lm_sensors  # Provides the 'sensors' command for monitoring temperatures
    nixpkgs-master.claude-code

    sesh
    gum

    nixfmt-rfc-style

    fastfetch
  ];
}
