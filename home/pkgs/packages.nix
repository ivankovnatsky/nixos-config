{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    kbdd
    arandr
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
    dogdns
    du-dust
    duf
    exa
    exiftool
    fd
    file
    fwts
    genpass
    geteltorito
    gettext
    gimp
    gitAndTools.pre-commit
    glances
    gnome3.adwaita-icon-theme
    gnumake
    hadolint
    htop
    hwinfo
    i2c-tools
    imagemagick
    irssi
    jq
    jsonnet
    k9s
    killall
    kubectl
    kubectx
    kubernetes-helm
    kubetail
    lm_sensors
    lshw
    maim
    mdl
    nixfmt
    nixpkgs-review
    nix-tree
    openssl
    pass
    pavucontrol
    pciutils
    ranger
    rclone
    ripgrep
    rofi
    rubber
    shellcheck
    signal-desktop
    strace
    sysstat
    tcpdump
    terragrunt
    tflint
    tfsec
    traceroute
    unzip
    usbutils
    viber
    wget
    xclip
    xorg.xev
    youtube-dl
    zathura
    zip

    (texlive.combine {
      inherit (texlive) scheme-small xetex collection-fontsrecommended moderncv;
    })

    (python38.withPackages (ps: with ps; [ grip rich ]))

    # FIXME: install specific version
    # (terraform_0_14.withPlugins (p: [
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
