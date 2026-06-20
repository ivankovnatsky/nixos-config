{
  imports = [
    ../../../../modules/home/launchd
    ../../../../modules/home/notifications
    ../../../../modules/home/reposync
    ./arr-mgmt.nix
    ./beszel-mgmt.nix
    ./miniserve.nix
    ./notifications.nix
    ./reposync.nix
    ./syncthing.nix
    ./uptime-kuma.nix
  ];
}
