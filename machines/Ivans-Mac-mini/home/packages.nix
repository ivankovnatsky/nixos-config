{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    cargo
    codex
    delta
    du-dust
    duf
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
    nixpkgs-master.claude-code
    nixpkgs-master.gemini-cli
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
