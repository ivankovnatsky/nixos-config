{ lib, pkgs, ... }:

{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/ba92c270-5d3c-4681-904d-61b8fe48ef73";
        preLVM = true;
      };
    };

    kernelParams = [
      "quiet"
    ];

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
