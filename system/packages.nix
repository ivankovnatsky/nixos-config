{ config, pkgs, ... }:

let
  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';
in
{
  environment.systemPackages = with pkgs; [
    _1password
    acpi
    awscli2
    aws-vault
    binutils-unwrapped
    brightnessctl
    chromium-work
    delta
    dhall
    dhall-json
    dmidecode
    dnsutils
    docker
    docker-compose
    dogdns
    du-dust
    duf
    envsubst
    exiftool
    file
    genpass
    geteltorito
    gimp
    git
    gnome3.adwaita-icon-theme
    gnome3.libsecret
    gnumake
    go
    google-cloud-sdk
    htop
    hwinfo
    imagemagick
    ipcalc
    iw
    jq
    jsonnet
    k9s
    keepassxc
    killall
    kubecolor
    kubectl
    kubectl-tree
    kubectx
    kubernetes-helm
    kubetail
    libnotify
    lm_sensors
    lshw
    mtr
    neovim
    networkmanagerapplet
    networkmanager-l2tp
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    nmap
    nodePackages.peerflix
    openssl
    p7zip
    pavucontrol
    pciutils
    postgresql
    powertop
    procs
    python38
    rclone
    ripgrep
    sops
    ssm-session-manager-plugin
    strace
    syncthing
    sysstat
    tealdeer
    terraform
    terraformer
    tflint
    unzip
    update-systemd-resolved
    usbutils
    viber
    wget
    whois
    youtube-dl
    zip

    (chromium.override {
      commandLineArgs =
        if config.device.graphicsEnv == "xorg" then
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=VaapiVideoDecoder,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end" else
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })
  ];
}
