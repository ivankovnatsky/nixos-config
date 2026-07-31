{
  pkgs,
  ...
}:

let
  whisperWithCuda = pkgs.python3Packages.openai-whisper.override {
    torch = pkgs.python3Packages.torchWithCuda;
  };
in
{
  home.packages = with pkgs; [
    (writeShellApplication {
      name = "whisper";
      runtimeInputs = [
        ffmpeg
        whisperWithCuda
      ];
      text = ''
        exec ${whisperWithCuda}/bin/whisper --device cuda "$@" --model large-v3
      '';
    })
    (python313.withPackages (
      ps: with ps; [
        grip
        markitdown
      ]
    ))
    unzip
    file
    cryptomator
    mpv
    unixtools.ifconfig
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
    pandoc
    parallel
    pciutils
    pulseaudio
    pv
    q
    ripgrep
    rclone
    rust-analyzer
    rustc
    typos
    typst
    typstyle
    uv
    velocidrone
    yq
    zsh-forgit
    rocmPackages.rocm-smi
    amdgpu_top
    fastfetch
    gnumake
    gum
    kdePackages.krdc # KDE Remote Desktop Client
    libnotify # Provides notify-send command
    lm_sensors # Provides the 'sensors' command for monitoring temperatures
    lsof # List open files
    nixfmt
    smartmontools # Disk health monitoring (smartctl)
    wl-clipboard # Wayland clipboard utilities
  ];
}
