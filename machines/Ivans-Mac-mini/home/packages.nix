{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    cargo
    delta
    du-dust
    duf
    exiftool
    fluxcd
    fzf
    gallery-dl
    genpass
    home-manager
    imagemagick
    jq
    k9s
    kail
    kubectl
    kubeseal
    kubernetes-helm
    macmon
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
    sesh
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
