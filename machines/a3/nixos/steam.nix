{
  config,
  lib,
  pkgs,
  ...
}:

# TODO: Steam Remote Play with powered off Monitor
{
  # Enable Steam
  programs.steam = {
    enable = true;
  };
}
