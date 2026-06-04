{
  boot.initrd.luks.devices."crypted-storage0" = {
    device = "/dev/disk/by-uuid/5fcf939d-159c-4d28-b748-4e83281422af";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/storage0" = {
    device = "/dev/mapper/crypted-storage0";
    fsType = "ext4";
  };

  systemd.tmpfiles.rules = [
    "d /storage0/data 0755 root users -"
  ];
}
