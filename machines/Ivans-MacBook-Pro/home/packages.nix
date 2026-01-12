{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        markitdown
      ]
    ))
    age
    aria2
    asusrouter-cli
    backup-home
    dns
    torrent-dl
    giffer
    git-message
    homelab
    launchd-mgmt
    gh-notifications
    ps-top-nu
    settings
    sops
    ssh-to-age
    swiftformat
    syncthing-mgmt
    tree
    uptime-kuma-mgmt
    watchman-rebuild
  ];
}
