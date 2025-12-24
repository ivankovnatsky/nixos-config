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
    ps-top-nu
    watchman-rebuild

    hyperfine
  ];
}
