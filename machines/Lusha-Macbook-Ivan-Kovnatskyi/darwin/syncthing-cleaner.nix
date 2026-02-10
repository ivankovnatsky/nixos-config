{ config, username, ... }:
let
  homeDir = config.users.users.${username}.home;
in
{
  local.services.syncthing-cleaner = {
    enable = true;
    intervalMinutes = 15;
    paths = [
      "${homeDir}/Sources/github.com/ivankovnatsky/nixos-config"
      "${homeDir}/Sources/github.com/ivankovnatsky/notes"
      "${homeDir}/Sources/github.com/NixOS/nixpkgs"
    ];
  };
}
