{
  boot.initrd.luks.devices."crypted-storage" = {
    device = "/dev/disk/by-uuid/8b23078c-481c-410f-a90c-88348b982ec1";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/storage" = {
    device = "/dev/mapper/crypted-storage";
    fsType = "ext4";
  };

  systemd.tmpfiles.rules = [
    "d /storage/data 0755 ivan users -"
  ];
}
