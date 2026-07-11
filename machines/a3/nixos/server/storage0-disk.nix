{ ... }:

{
  boot.initrd.luks.devices."crypted-storage0" = {
    device = "/dev/disk/by-uuid/5fcf939d-159c-4d28-b748-4e83281422af";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/storage0" = {
    device = "/dev/mapper/crypted-storage0";
    fsType = "ext4";
  };

  fileSystems."/storage/data/backup" = {
    device = "/storage0/data/backup";
    fsType = "none";
    options = [
      "bind"
      "x-systemd.requires-mounts-for=/storage0/data/backup"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /storage0/data 0755 root users -"
    # miniserve (home-manager user unit) uploads here; needs ivan-owned dir.
    "d /storage0/data/backup 0755 ivan users -"
    "d /storage0/data/vault 0755 ivan users -"
    "d /storage0/data/.backup 0755 ivan users -"
    "d /storage0/data/.scripts 0755 ivan users -"
  ];
}
