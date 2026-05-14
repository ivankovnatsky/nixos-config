{ inputs, pkgs, system, ... }:

let
  steipeteTools = inputs.nix-steipete-tools.packages.${system};
in
{
  home.packages =
    (with pkgs; [
      (python313.withPackages (
        ps: with ps; [
          grip
          markitdown
        ]
      ))
      mpv
      unixtools.ifconfig
      git-restore
      backup-system
      bat
      bubblewrap
      cargo
      curlie
      dig
      doggo
      duf
      erdtree
      exiftool
      game-mode
      gh-repos-sync
      glow
      hadolint
      home-manager
      imagemagick
      magic-wormhole
      mkpasswd
      nethogs
      nh
      nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
      pandoc
      parallel
      pciutils
      power-consumption
      pre-commit
      pv
      q
      ripgrep
      rust-analyzer
      rustc
      temperatures
      tmux-temperatures
      typos
      typst
      typstyle
      uv
      velocidrone
      yazi
      yq
      zsh-forgit
    ])
    ++ (with steipeteTools; [
      summarize
      sag
    ]);
}
