{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
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
    go-grip
    git-dotfiles
    git-message
    homelab
    hyperfine
    launchd-mgmt
    poppler-utils
    poweroff
    ps-top-nu
    settings
    sops
    ssh-to-age
    syncthing-mgmt
    tree
    uptime-kuma-mgmt
    watchman-rebuild
  ];
}
