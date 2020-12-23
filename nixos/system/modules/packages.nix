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
