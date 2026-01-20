{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        markitdown
      ]
    ))
    age
    aria2
    asusrouter-cli
    backup-home
    dns
    torrent-dl
    ffmpeg
    giffer
    git-message
    homelab
    launchd-mgmt
    gh-notifications
    nixpkgs-darwin-master-opencode.opencode
    ps-top-nu
    settings
    sops
    poweroff
    git-dotfiles
    ssh-to-age
    swiftformat
    syncthing-mgmt
    tree
    uptime-kuma-mgmt
    watchman-rebuild
  ];
}
