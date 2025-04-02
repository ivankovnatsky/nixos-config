{
  boot = {
    # Configure LUKS with TPM2 support
    initrd = {
      # ```dmesg
      # [    1.290179] usb 2-3: new SuperSpeed Plus Gen 2x1 USB device number 2 using xhci_hcd [    1.303060] usb 2-3: New USB device found, idVendor=04e8, idProduct=4001, bcdDevice= 1.00
      # [    1.303078] usb 2-3: New USB device strings: Mfr=2, Product=3, SerialNumber=1
      # [    1.303085] usb 2-3: Product: PSSD T7
      # [    1.303089] usb 2-3: Manufacturer: Samsung
      # [    1.303093] usb 2-3: SerialNumber: [redacted]
      # [    1.329668] scsi host2: uas
      # [    1.329914] usbcore: registered new interface driver uas
      # [    1.331423] scsi 2:0:0:0: Direct-Access     Samsung  PSSD T7          0    PQ: 0 ANSI: 6
      # [    1.333652] sd 2:0:0:0: [sdb] 7814037168 512-byte logical blocks: (4.00 TB/3.64 TiB)
      # [    1.333759] sd 2:0:0:0: [sdb] Write Protect is off
      # [    1.333764] sd 2:0:0:0: [sdb] Mode Sense: 43 00 00 00
      # [    1.333946] sd 2:0:0:0: [sdb] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
      # [    1.360322] sd 2:0:0:0: [sdb] Preferred minimum I/O size 512 bytes
      # [    1.360337] sd 2:0:0:0: [sdb] Optimal transfer size 33553920 bytes
      # [    1.364652] sdb: sdb1
      # [    1.364884] sd 2:0:0:0: [sdb] Attached SCSI disk
      # ```
      availableKernelModules = ["uas"];

      # LUKS device configurations
      luks.devices = {
        # Samsung 4TB storage
        "samsung-crypt" = {
          device = "/dev/disk/by-uuid/e9d01b26-cab2-47df-8da8-ed4e0e3d4cb0";
          preLVM = true;  # This is important since LVM is on top of LUKS
          crypttabExtraOpts = [ "tpm2-device=auto" ];
          allowDiscards = true;  # For SSD TRIM support
        };
      };
    };
  };
  fileSystems = {
    "/storage" = {
      device = "/dev/mapper/samsung--vg-samsung--lv";
      fsType = "ext4";
      options = ["nofail" ];  # Continue boot if mount fails
    };
  };
}
