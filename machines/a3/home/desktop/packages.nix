{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # `whisper` is uv-installed (openai-whisper, prebuilt CUDA wheel — see tools.nix),
    # NOT the nixpkgs python3Packages.openai-whisper: the nixpkgs CUDA path pulls
    # torchWithCuda, which has no binary cache here and compiles torch + magma from
    # source for all supported GPU archs — well over an hour on this box. The uv wheel
    # downloads in seconds. This wrapper only supplies the NixOS runtime glue the
    # prebuilt torch needs: libstdc++ (stdenv.cc.cc.lib) and the NVIDIA driver
    # (/run/opengl-driver/lib), which a plain foreign wheel can't find on NixOS.
    (writeShellApplication {
      name = "whisper";
      runtimeInputs = [ ffmpeg ];
      text = ''
        export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        exec "$HOME/.local/share/uv/tools/openai-whisper/bin/whisper" --device cuda --model large-v3 "$@"
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
    mpv
    unixtools.ifconfig
    backup-system
    subs
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
