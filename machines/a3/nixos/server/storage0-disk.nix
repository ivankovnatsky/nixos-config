{
  boot.initrd.luks.devices."crypted-storage0" = {
    device = "/dev/disk/by-uuid/a8787cc5-d5bb-4dfb-b4e0-2bccbffd9fe4";
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
