{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    battery-toolkit # Local overlay
    btop
    cargo
    duf
    erdtree
    exiftool
    fzf
    gallery-dl
    home-manager
    imagemagick
    launchd-mgmt
    magic-wormhole
    mkpasswd
    nixfmt-rfc-style
    pandoc
    parallel
    pv
    rclone
    rems
    ripgrep
    rust-analyzer
    rustc
    smctemp # Local overlay
    swiftformat
    syncthing
    taskwarrior-web # Local overlay
    typst
    typstyle
    watchman
    watchman-make
    zsh-forgit
  ];
}
