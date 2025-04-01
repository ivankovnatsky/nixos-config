{
  boot = {
    # Configure LUKS with TPM2 support
    initrd = {
      # LUKS device configurations
      luks.devices = {
        # Samsung 4TB storage
        "samsung-crypt" = {
          device = "/dev/disk/by-uuid/e9d01b26-cab2-47df-8da8-ed4e0e3d4cb0";
          preLVM = true;  # This is important since LVM is on top of LUKS
          allowDiscards = true;  # For SSD TRIM support
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };
      };
    };
  };
  fileSystems = {
    "/storage" = {
      device = "/dev/mapper/samsung--vg-samsung--lv";
      fsType = "ext4";
    };
  };

  # Ensure the mount point exists
  # systemd.tmpfiles.rules = [
  #   "d /storage 0755 root root -"
  # ];
}
