{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    hadolint
    tdesktop
    signal-desktop
    teams
    gnome3.adwaita-icon-theme
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
    nix-tree
    docker-compose
    du-dust
    duf
    exa
    exiftool
    fd
    file
    fwts
    genpass
    geteltorito
    gimp
    gitAndTools.pre-commit
    glances
    gnome3.nautilus
    gnumake
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
    pass
    pavucontrol
    pciutils
    powertop
    ranger
    rclone
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

    (terraform_0_14.withPlugins (p: [
      p.archive
      p.aws
      p.external
      p.gitlab
      p.grafana
      p.helm
      p.kubernetes
      p.local
      p.null
      p.random
      p.template
      p.tls
    ]))

  ];
}
