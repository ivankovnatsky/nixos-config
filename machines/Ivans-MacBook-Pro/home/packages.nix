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
    coconutbattery # macOS: Battery
    delta
    du-dust
    duf
    erdtree
    exiftool
    fzf
    genpass
    home-manager
    imagemagick
    jq
    keycastr # macOS: Keystroke visualizer
    ks
    magic-wormhole
    mkpasswd
    mos # macOS: System stats
    nixfmt-rfc-style
    nodejs
    parallel
    pigz
    rclone
    rectangle # macOS: Window manager
    ripgrep
    rust-analyzer
    rustc
    smctemp # Local overlay
    stats # macOS: System stats
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
