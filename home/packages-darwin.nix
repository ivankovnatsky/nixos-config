{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    battery-toolkit # Local overlay
    btop
    launchd-mgmt
    cargo
    delta
    dust
    duf
    erdtree
    exiftool
    fzf
    gallery-dl
    genpass
    home-manager
    imagemagick
    jq
    magic-wormhole
    mkpasswd
    nixfmt-rfc-style
    nodejs
    gh-notifications
    pandoc
    parallel
    pigz
    pv
    rclone
    rems
    ripgrep
    rust-analyzer
    rustc
    dns
    smctemp # Local overlay
    settings
    swiftformat
    syncthing
    syncthing-mgmt
    taskwarrior-web # Local overlay
    typst
    typstyle
    username # Installed as flake
    watchman
    watchman-make
    wget
    zsh-forgit
  ];
}
