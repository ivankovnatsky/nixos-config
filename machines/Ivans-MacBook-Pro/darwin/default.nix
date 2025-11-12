{
  imports = [
    ./dock.nix
    ./homebrew.nix
    ../../../modules/darwin/rebuild-daemon
    ./nextdns
    ./syncthing-mgmt.nix
    ./rebuild-daemon.nix
    ./git.nix
    ../../../darwin/no-dock-restart.nix
  ];
}
