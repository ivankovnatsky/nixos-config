{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    acpi
    alacritty
    arandr
    awscli2
    aws-iam-authenticator
    bat
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    clinfo
    dmenu
    dmidecode
    dnsutils
    docker
    docker-compose
    du-dust
    duf
    exa
    exiftool
    fd
    firefox
    fzf
    gimp
    git
    gitAndTools.pre-commit
    glances
    gnumake
    htop
    i2c-tools
    imagemagick
    irssi
    jq
    k9s
    killall
    kubectl
    kubectx
    kubernetes-helm
    lm_sensors
    lshw
    maim
    mpv
    networkmanagerapplet
    networkmanager-l2tp
    nixfmt
    nixpkgs-review
    pamixer
    pavucontrol
    pciutils
    powertop
    ranger
    ripgrep
    rubber
    shellcheck
    signal-desktop
    starship
    strace
    taskwarrior
    tcpdump
    tdesktop
    terragrunt
    tflint
    tfsec
    tmuxinator
    traceroute
    tree
    unzip
    viber
    vulkan-tools
    wget
    xclip
    xorg.xev
    xorg.xprop
    youtube-dl
    zathura
    zip

    (google-chrome.override {
      commandLineArgs = "--enable-accelerated-video-decode --enable-vulkan";
    })

    (texlive.combine {
      inherit (texlive) scheme-small xetex collection-fontsrecommended moderncv;
    })

    (python38.withPackages (ps: with ps; [ grip ]))

    (dwm.override {
      conf = builtins.readFile ./../../../suckless/dwm/config.h;
      patches = builtins.map pkgs.fetchurl [
        {
          url = "https://dwm.suckless.org/patches/notitle/dwm-notitle-6.2.diff";
          sha256 = "0lr7l98jc88lwik3hw22jq7pninmdla360c3c7zsr3s2hiy39q9f";
        }
        {
          url = "https://dwm.suckless.org/patches/pwkl/dwm-pwkl-6.2.diff";
          sha256 = "0qq3mlcp55p5dx9jmd75rkxlsdihzh4a2z1qzpljqash14kqsqzm";
        }
      ];
    })

    # (terraform_0_11.withPlugins (p: [
    #   p.archive
    #   p.aws
    #   p.external
    #   p.gitlab
    #   p.grafana
    #   p.helm
    #   p.kubernetes
    #   p.local
    #   p.null
    #   p.random
    #   p.template
    #   p.tls
    # ]))
  ];
}
