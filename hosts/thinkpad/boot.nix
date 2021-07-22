{ lib, pkgs, ... }:

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
      "acpi_backlight=native"

      "acpi_osi=linux"
      "tsc=nowatchdog"
      "iommu=pt"
    ];

    kernelPackages = pkgs.linuxPackagesFor
      (pkgs.linux_testing.override {
        argsOverride = rec {
          src = pkgs.fetchurl {
            url = "https://git.kernel.org/stable/t/linux-${version}.tar.gz";
            sha256 = "sha256-tHA3JFuoh5s6DgQe7tK8snkaSmal0uYZhMNPTk5GzX8=";
          };
          version = "5.14-rc2";
          modDirVersion = "5.14.0-rc2";
        };

        ignoreConfigErrors = true;

        structuredExtraConfig = with lib.kernel; {
          AMD_PMC = yes;
          I2C_HID_ACPI = module;
          HSA_AMD = lib.mkForce (option no);
        };
      });

    kernelPatches = [
      {
        name = "5.14-rc1+git+patch";
        patch = builtins.fetchurl {
          url = "https://crazy.dev.frugalware.org/S0ix-5.14rc1.patch";
          sha256 = "129wdnj92r0dry0ca5id7rwbnqaz0mvs72nj6x873yb0kv6jqrsy";
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
