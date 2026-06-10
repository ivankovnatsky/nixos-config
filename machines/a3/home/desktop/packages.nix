{
  inputs,
  pkgs,
  system,
  ...
}:

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
      unzip
      mpv
      nixpkgs-nixos-master-edge.antigravity-cli
      rumdl
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
      glow
      hadolint
      home-manager
      imagemagick
      magic-wormhole
      mkpasswd
      nethogs
      nh
      nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
      openai-whisper # `whisper` CLI, used by openclaw's tools.media.audio
      pandoc
      parallel
      pciutils
      pre-commit
      pulseaudio
      pv
      q
      ripgrep
      rust-analyzer
      rustc
      typos
      typst
      typstyle
      uv
      velocidrone
      yazi
      yq
      zsh-forgit
      rocmPackages.rocm-smi
      amdgpu_top
      fastfetch
      ghq-cd
      gnumake
      gum
      kdePackages.krdc # KDE Remote Desktop Client
      pinentry-qt # Qt pinentry for GPG
      libnotify # Provides notify-send command
      lm_sensors # Provides the 'sensors' command for monitoring temperatures
      lsof # List open files
      nixfmt
      smartmontools # Disk health monitoring (smartctl)
      wl-clipboard # Wayland clipboard utilities
    ])
    ++ (with steipeteTools; [
      summarize
      sag
    ]);
}
