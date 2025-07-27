{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Add Wayland flags to Windsurf to fix scaling issues
    # (windsurf.override {
    #   # Use commandLineArgs to add Wayland flags
    #   commandLineArgs = [
    #     "--ozone-platform=wayland"
    #   ];
    # })
    windsurf

    # Hardware monitoring tools
    lm_sensors  # Provides the 'sensors' command for monitoring temperatures
    nixpkgs-master.claude-code

    sesh
    gum

    nixfmt-rfc-style
  ];
}
