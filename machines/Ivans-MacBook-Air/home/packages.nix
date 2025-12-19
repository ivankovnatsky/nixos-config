{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    switch-scaling
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

    switch-appearance
    switch-appearance-go
    switch-appearance-py
    switch-appearance-rs
    switch-appearance-zig
    switch-appearance-c

    hyperfine
  ];
}
