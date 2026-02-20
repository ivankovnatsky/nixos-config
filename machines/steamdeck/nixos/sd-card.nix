{ config, lib, pkgs, ... }:

{
  fileSystems."/run/media/mmcblk0p1" = {
    device = "/dev/disk/by-uuid/56a47c24-d236-4f50-b010-bd31dd058d6d";
    fsType = "ext4";
    options = [
      "nofail"
      "nosuid"
      "nodev"
      "relatime"
      "errors=remount-ro"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /run/media/mmcblk0p1 0755 root root -"
  ];
}
