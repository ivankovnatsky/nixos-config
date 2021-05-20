{ pkgs, ... }:

let
  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';

  viber-run = pkgs.writeScriptBin "viber-run" ''
    #!/usr/bin/env bash

    QT_QPA_PLATFORM=xcb ${pkgs.viber}/bin/viber
  '';

in
{
  environment.systemPackages = with pkgs; [
    acpi
    awscli2
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    capitaine-cursors
    chromium-work
    dmidecode
    dnsutils
    docker
    docker-compose
    dogdns
    du-dust
    duf
    exa
    fd
    file
    genpass
    geteltorito
    gimp
    gitAndTools.pre-commit
    git-crypt
    gnome3.adwaita-icon-theme
    gnome3.eog
    gnome3.libsecret
    gnome3.nautilus
    gnumake
    google-cloud-sdk
    htop
    hwinfo
    imagemagick
    iw
    jq
    k9s
    keepassxc
    killall
    kubectl
    kubectx
    kubernetes-helm
    libnotify
    lm_sensors
    lshw
    mdl
    networkmanagerapplet
    networkmanager-l2tp
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    openssl
    pavucontrol
    pciutils
    pulseaudio
    rclone
    ripgrep
    shellcheck
    strace
    sysstat
    terraform
    terragrunt
    unzip
    usbutils
    v4l-utils
    vulkan-tools
    viber-run
    wget
    xdg-utils
    youtube-dl
    zip

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })
  ];
}
