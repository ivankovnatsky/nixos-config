{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # bitwarden-cli  # FIXME: Fails to install on current nixpkgs-unstable
    # nodePackages.webtorrent-cli  # FIXME: Fails to install on current nixpkgs-unstable
    (python312.withPackages (ps: with ps; [ grip ]))
    aria2
    backup-home # Installed as flake
    bat
    battery-toolkit # Local overlay
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
    ks
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
