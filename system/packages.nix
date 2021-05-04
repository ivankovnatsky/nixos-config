{ pkgs, ... }:

let
  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';

  firefox-work = pkgs.writeScriptBin "firefox-work" ''
    #!/usr/bin/env bash

    firefox -P work
  '';

in {
  environment.systemPackages = with pkgs; [
    acpi
    awless
    awscli2
    aws-iam-authenticator
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    chromium-work
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
    firefox-work
    fwts
    genpass
    geteltorito
    gettext
    gimp
    google-cloud-sdk
    gitAndTools.pre-commit
    glances
    gnome3.adwaita-icon-theme
    gnome3.eog
    gnome3.libsecret
    gnome3.nautilus
    gnumake
    gping
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
    libnotify
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
    v4l-utils
    vulkan-tools
    wget
    youtube-dl
    zathura
    zip

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })

    (python38.withPackages (ps: with ps; [ grip rich ]))

    terraform
  ];
}
