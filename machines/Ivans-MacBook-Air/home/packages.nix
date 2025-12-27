{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    settings
    tree
    asusrouter-cli
    nodePackages.prettier
    treefmt
    sops
    age
    ssh-to-age
    syncthing-mgmt
    dns
    download-torrent
    git-message
    poweron-homelab
    ps-top-nu
    watchman-rebuild

    hyperfine
  ];
}
