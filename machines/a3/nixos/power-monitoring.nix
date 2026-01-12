{ pkgs, config, ... }:

{
  # Enable MSR (Model Specific Registers) for CPU power monitoring
  # Required for MangoHud and other tools to read CPU power consumption
  boot.kernelModules = [
    "msr"
    "zenpower"
  ];

  # zenpower3 kernel module for AMD CPU power readings in MangoHud
  # https://github.com/flightlessmango/MangoHud/issues/1855
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

  # Blacklist k10temp - conflicts with zenpower (both use same PCI device)
  boot.blacklistedKernelModules = [ "k10temp" ];

  # Make RAPL energy files readable for MangoHud CPU power display
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl*/energy_uj 0444 root root -"
  ];

  environment.systemPackages = with pkgs; [
    powerstat
  ];
}
