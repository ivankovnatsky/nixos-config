{
  boot.initrd.luks.devices."crypted-storage" = {
    device = "/dev/disk/by-uuid/8b23078c-481c-410f-a90c-88348b982ec1";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/storage" = {
    device = "/dev/mapper/crypted-storage";
    fsType = "ext4";
  };

  # Owned by root (not ivan) so systemd-tmpfiles can canonicalize through
  # this dir into service-user-owned descendants (e.g. /storage/data/media/...).
  # Tmpfiles refuses unprivileged → other-user transitions during path
  # traversal, which previously prevented .incomplete / watchdir / *arr
  # subdirs of /storage/data/media/downloads from being created.
  systemd.tmpfiles.rules = [
    "d /storage/data 0755 root users -"
  ];
}
