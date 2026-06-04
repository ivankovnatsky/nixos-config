{ pkgs, config, ... }:

{
  # Enable MSR (Model Specific Registers) for CPU power monitoring
  # Required for MangoHud and other tools to read CPU power consumption
  boot.kernelModules = [
    "msr"
    "zenpower"
    "k10temp"
    "nct6687"
  ];

  # zenpower3 kernel module for AMD CPU power readings in MangoHud
  # https://github.com/flightlessmango/MangoHud/issues/1855
  # nct6687d for MSI MAG B850M Mortar board sensors (voltages, fan speeds)
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower nct6687d ];

  # Make RAPL energy files readable for MangoHud CPU power display
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl*/energy_uj 0444 root root -"
  ];

  environment.systemPackages = with pkgs; [
    powerstat
  ];
}
