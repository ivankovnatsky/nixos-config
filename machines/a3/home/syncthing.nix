{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable Syncthing service for user
  services.syncthing = {
    enable = true;
  };
}
