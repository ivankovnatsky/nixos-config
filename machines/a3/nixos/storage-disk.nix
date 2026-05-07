{
  boot.initrd.luks.devices."crypted-data" = {
    device = "/dev/disk/by-uuid/a8787cc5-d5bb-4dfb-b4e0-2bccbffd9fe4";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/storage" = {
    device = "/dev/mapper/crypted-data";
    fsType = "ext4";
  };

  systemd.tmpfiles.rules = [
    "d /storage/data 0755 ivan users -"
  ];
}
