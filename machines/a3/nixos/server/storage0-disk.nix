{ pkgs, ... }:

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
      "x-systemd.requires=storage-data-backup-bind-source.service"
      "x-systemd.after=storage-data-backup-bind-source.service"
    ];
  };

  systemd.services.storage-data-backup-bind-source = {
    description = "Prepare /storage/data/backup bind mount source";
    requiredBy = [ "storage-data-backup.mount" ];
    before = [ "storage-data-backup.mount" ];
    requires = [
      "storage.mount"
      "storage0.mount"
    ];
    after = [
      "storage.mount"
      "storage0.mount"
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/install -d -o ivan -g users -m 0755 /storage0/data/backup
      ${pkgs.coreutils}/bin/install -d -o ivan -g users -m 0755 /storage0/data/backup/Machines
      ${pkgs.coreutils}/bin/install -d -o root -g users -m 0755 /storage/data/backup
    '';
  };

  systemd.tmpfiles.rules = [
    "d /storage0/data 0755 root users -"
    # miniserve (home-manager user unit) uploads here; needs ivan-owned dir.
    "d /storage0/data/backup 0755 ivan users -"
    "d /storage0/data/backup/Machines 0755 ivan users -"
    # rclone sync target for iCloud Drive contents.
    "d /storage0/data/iclouddrive 0755 ivan users -"
  ];
}
