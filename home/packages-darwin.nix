{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    battery-toolkit # Local overlay
    btop
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
    open-gh-notifications-py
    pandoc
    parallel
    pigz
    pv
    rclone
    ripgrep
    rust-analyzer
    rustc
    dns
    smctemp # Local overlay
    switch-appearance
    syncthing
    syncthing-mgmt
    typst
    typstfmt
    username # Installed as flake
    watchman
    watchman-make
    wget
    zsh-forgit
  ];
}
