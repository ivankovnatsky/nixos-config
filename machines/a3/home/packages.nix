{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        markitdown
      ]
    ))
    git-restore
    backup-system
    bat
    cargo
    claude-code-logs
    curlie
    doggo
    duf
    erdtree
    exiftool
    gallery-dl
    game-mode
    ggh
    glow
    hadolint
    home-manager
    imagemagick
    magic-wormhole
    mkpasswd
    nethogs
    nh
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    obsidian-cli
    pandoc
    parallel
    power-consumption
    pre-commit
    pv
    q
    rclone
    ripgrep
    rust-analyzer
    rustc
    steam-mgmt
    temperatures
    tmux-temperatures
    typst
    typstyle
    uv
    velocidrone
    yazi
    yq
    zsh-forgit
  ];
}
