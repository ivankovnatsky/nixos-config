{ pkgs, ... }:

{
  # Install packages needed for automatic rebuilds
  environment.systemPackages = with pkgs; [
    gnumake
    watchman
    watchman-make
  ];
}
