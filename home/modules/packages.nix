{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    arandr
    file
    awless
    awscli2
    aws-iam-authenticator
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    dmidecode
    dnsutils
    docker-compose
    du-dust
    duf
    exa
    exiftool
    fd
    genpass
    geteltorito
    gimp
    gitAndTools.pre-commit
    glances
    gnumake
    htop
    hwinfo
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
    nixfmt
    nixpkgs-review
    pass
    pavucontrol
    pciutils
    powertop
    ranger
    ripgrep
    rubber
    shellcheck
    strace
    tcpdump
    terragrunt
    tflint
    tfsec
    traceroute
    tree
    unzip
    mdl
    usbutils
    viber
    wget
    xclip
    xorg.xev
    xorg.xprop
    youtube-dl
    zathura
    zip
    i3status-rust

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
