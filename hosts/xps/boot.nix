{ lib, pkgs, ... }:

{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/e5dad8a3-9b94-4d27-b46a-281d07802b3b";
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
