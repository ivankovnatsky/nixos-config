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
    #
    # To use it by default:
    # docker buildx install
    # docker buildx use default
    # docker buildx inspect --bootstrap
    docker-buildx
    qemu
  ];
}
