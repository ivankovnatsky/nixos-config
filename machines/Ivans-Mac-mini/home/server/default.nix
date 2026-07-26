{
  imports = [
    ../../../../darwin/unison.nix
    ../../../../modules/home/launchd
    ../../../../modules/home/notifications
    ../../../../modules/home/tools
    ../../../../modules/home/unison
    ./anker-monitor.nix
    ./notifications.nix
    ./reposync.nix
    ./syncthing-mgmt.nix
  ];
}
