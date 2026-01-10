{ pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    aria2
    asusrouter-cli
    backup-home
    giffer
    dns
    download-torrent
    git-message
    nodePackages.prettier
    open-gh-notifications-py
    homelab
    launchd-mgmt
    ps-top-nu
    python313Packages.osxphotos
    sops
    ssh-to-age
    swiftformat
    settings
    syncthing-mgmt
    uptime-kuma-mgmt
    tree
    treefmt
    watchman-rebuild
  ];
}
