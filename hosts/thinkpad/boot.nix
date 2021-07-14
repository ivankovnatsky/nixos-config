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
      "quiet"
      "amd_iommu=pt"
      "iommu=soft"
      "acpi_backlight=native"
      "acpi_osi=linux"
    ];

    # kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_testing.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "https://git.kernel.org/stable/t/linux-${version}.tar.gz";
          sha256 = "sha256-IeEqcNhSc5NlkbZabk5ai0eLUO0PPIOobJIeZoS54AU=";
        };
        version = "5.13.1";
        modDirVersion = "5.13.1";
      };

      ignoreConfigErrors = true;
    });

    kernelPatches = [
      {
        name = "5.13.1-S0ix-AMD-all-in-one";
        patch = builtins.fetchurl {
          url = "https://crazy.dev.frugalware.org/5.13.1-S0ix-AMD-all-in-one.patch";
          sha256 = "1b5wkhcpllsgbi4cv8bh63a2k4m5cbg9l4ll99k1fysa3bafnk06";
        };
      }
    ];

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
