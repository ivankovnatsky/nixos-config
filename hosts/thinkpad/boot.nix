{ pkgs, ... }:

{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/28eb4c4d-9c50-44ae-b046-613c7eaac520";
        preLVM = true;
      };
    };

    blacklistedKernelModules = [ "r8152" ];
    kernelParams = [
      "amd_iommu=pt"
      "iommu=soft"
      "acpi_backlight=native"
    ];

    kernelPackages = pkgs.linuxPackages_5_13;

    extraModprobeConfig = ''
      # idle audio card after one second
      options snd_hda_intel power_save=1

      # enable wifi power saving (keep uapsd off to maintain low latencies)
      options iwlwifi power_save=1 uapsd_disable=1

      # possible fix for WiFi disconnects
      options iwlwifi 11n_disable=8
    '';
  };
}
