{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    binutils-unwrapped
    dmidecode
    dnsutils
    docker
    docker-compose
    git
    hwinfo
    iw
    lm_sensors
    lshw
    neovim
    pciutils
    strace
    sysstat

    # To install arm emulator:
    # docker run --privileged --rm tonistiigi/binfmt --install arm64
    docker-buildx
    qemu
  ];
}
