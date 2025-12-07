{ pkgs, ... }:
{
  home.packages = with pkgs; [
    aria2
    tree
    asusrouter-cli
    nodePackages.prettier
    swiftformat
    treefmt
    sops
    age
    ssh-to-age
    syncthing-mgmt
    open-gh-notifications-py
    dns
    watchman-rebuild
  ];
}
