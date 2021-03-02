{ pkgs, ... }:

{
  home.packages = with pkgs; [
    acpi
    gping
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
    gnome3.eog
    genpass
    geteltorito
    gettext
    gimp
    gitAndTools.pre-commit
    glances
    gnome3.adwaita-icon-theme
    gnome3.nautilus
    gnome3.libsecret
    gnumake
    hadolint
    htop
    hwinfo
    i2c-tools
    imagemagick
    irssi
    iw
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
    rubber
    shellcheck
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
    youtube-dl
    zathura
    zip

    (texlive.combine {
      inherit (texlive) scheme-small xetex collection-fontsrecommended moderncv;
    })

    (python38.withPackages (ps: with ps; [ grip rich ]))

    terraform-custom
  ];
}
