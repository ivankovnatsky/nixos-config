{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    backup-home
    giffer
    settings
    tree
    asusrouter-cli
    nodePackages.prettier
    treefmt
    sops
    age
    ssh-to-age
    syncthing-mgmt
    uptime-kuma-mgmt
    dns
    download-torrent
    git-message
    homelab
    launchd-mgmt
    ps-top-nu
    python313Packages.osxphotos
    watchman-rebuild

    hyperfine
  ];
}
