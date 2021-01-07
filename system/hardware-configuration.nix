# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/28eb4c4d-9c50-44ae-b046-613c7eaac520";
        preLVM = true;
      };

      availableKernelModules = [
        "nvme"
        "ehci_pci"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
    };

    kernelModules = [ "dm-snapshot" "kvm-amd" "amdgpu" ];
    kernelParams = [ "amd_iommu=pt" "iommu=soft" ];

    extraModprobeConfig = ''
      options iwlwifi 11n_disable=8
    '';

    extraModulePackages = [ ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/163f1fae-736e-40ff-a7c2-5e65c9104fd1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6924-5A00";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/fa4ae5ad-dbd8-4aa0-96d3-cbc9850d0121"; }];
}
