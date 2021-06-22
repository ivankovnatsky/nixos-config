{ pkgs, ... }:

{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/0a656fc7-bc28-4591-a0bc-e440cce57830";
        preLVM = true;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
