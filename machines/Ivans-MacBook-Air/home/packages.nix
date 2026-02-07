{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages ( ps: with ps; [ grip markitdown ]))
    age
    aria2
    asusrouter-cli
    backup-home
    dns
    ffmpeg
    gh-notifications
    giffer
    git-dotfiles
    git-message
    go-grip
    homelab
    hyperfine
    launchd-mgmt
    poppler-utils
    poweroff
    ps-top-nu
    settings
    sops
    ssh-to-age
    swiftformat
    syncthing-mgmt
    torrent-dl
    tree
    uptime-kuma-mgmt
    watchman-rebuild
  ];
}
