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

in
{
  environment.systemPackages = with pkgs; [
    acpi
    awscli2
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
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
    firefox-work
    genpass
    geteltorito
    gimp
    gitAndTools.pre-commit
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
    nixfmt
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
    viber
    v4l-utils
    vulkan-tools
    wget
    youtube-dl
    zip

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })
  ];
}
