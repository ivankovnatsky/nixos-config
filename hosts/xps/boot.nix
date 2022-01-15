{ lib, pkgs, ... }:

{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/8af34f16-dec9-45b5-ad73-05cdc6bca6aa";
        preLVM = true;
      };

      kernelModules = [ "i915" ];
    };

    blacklistedKernelModules = [ "psmouse" ];

    kernelParams = [
      "quiet"
    ];

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
