{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        markitdown
      ]
    ))
    obs
    age
    aria2
    asusrouter-cli
    backup-home
    cleanup-home
    delta
    discordo
    dns
    dust
    ffmpeg
    genpass
    ghq-cd
    gh-notifications
    giffer
    git-message
    gpg-pass-refresh
    go-grip
    gwq
    homelab
    hyperfine
    jq
    nodejs
    notes
    pigz
    poppler-utils
    poweroff
    ps-top-nu
    find-grep
    rg-all
    rg-find
    settings
    sops
    ssh-to-age
    syncthing-mgmt
    taskmanager
    torrent-dl
    tree
    username # Installed as flake
    uptime-kuma-mgmt
    wget
    rebuild
  ];
}
