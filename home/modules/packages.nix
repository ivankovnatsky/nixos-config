{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    arandr
    awless
    awscli2
    aws-iam-authenticator
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    kubetail
    linuxPackages.cpupower
    linuxPackages.turbostat
    dmidecode
    eksctl
    dnsutils
    jsonnet
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
    gnome3.nautilus
    gnumake
    hadolint
    htop
    hwinfo
    i2c-tools
    i3status-rust
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
    tcpdump
    terragrunt
    tflint
    tfsec
    traceroute
    tree
    unzip
    usbutils
    viber
    lf
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
