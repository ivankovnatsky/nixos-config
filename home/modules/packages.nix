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
    dmidecode
    dnsutils
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
    pass
    pavucontrol
    pciutils
    powertop
    ranger
    rclone
    ripgrep
    rubber
    shellcheck
    signal-desktop
    strace
    tcpdump
    tdesktop
    rofi
    teams
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
