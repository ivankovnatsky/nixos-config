{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        markitdown
      ]
    ))
    rems
    obs
    age
    aria2
    asusrouter-cli
    backup-home
    cleanup-home
    discordo
    dns
    ffmpeg
    gh-notifications
    giffer
    dotfiles
    git-message
    gpg-pass-refresh
    go-grip
    homelab
    hyperfine
    launchd-mgmt
    notes
    poppler-utils
    poweroff
    ps-top-nu
    find-grep
    rg-all
    rg-find
    settings
    sops
    ssh-to-age
    swiftformat
    syncthing-mgmt
    taskmanager
    torrent-dl
    tree
    uptime-kuma-mgmt
    watchman-rebuild
  ];
}
