{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    acpi
    awless
    awscli2
    aws-iam-authenticator
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    clinfo
    dmidecode
    dnsutils
    docker
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
    gnome3.eog
    gnome3.libsecret
    gnome3.nautilus
    gnumake
    gping
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
    keepassxc
    killall
    kubectl
    kubectx
    kubernetes-helm
    kubetail
    lm_sensors
    lshw
    mdl
    networkmanagerapplet
    networkmanager-l2tp
    nixfmt
    nixpkgs-review
    nix-tree
    openssl
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
    vulkan-tools
    wget
    youtube-dl
    zathura
    zip

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })

    (texlive.combine {
      inherit (texlive) scheme-small xetex collection-fontsrecommended moderncv;
    })

    (python38.withPackages (ps: with ps; [ grip rich ]))

    terraform-custom
  ];
}
