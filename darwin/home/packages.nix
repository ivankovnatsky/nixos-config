{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    battery-toolkit # Local overlay
    btop
    cargo
    delta
    du-dust
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
    pandoc
    parallel
    pigz
    pv
    rclone
    ripgrep
    rust-analyzer
    rustc
    smctemp # Local overlay
    switch-appearance
    syncthing
    typst
    typstfmt
    username # Installed as flake
    watchman
    watchman-make
    wget
    yt-dlp
    zsh-forgit
  ];
}
