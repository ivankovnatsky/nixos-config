{
  imports = [
    ../../../../modules/home/launchd
    ../../../../modules/home/notifications
    ../../../../modules/home/tools
    ../../../../modules/home/unison
    ./notifications.nix
    ./reposync.nix
    ./syncthing-mgmt.nix
    ../../../../darwin/unison.nix
  ];
}
