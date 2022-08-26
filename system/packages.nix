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
  ];
}
