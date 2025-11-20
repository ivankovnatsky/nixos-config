{ ... }:

{
  # Enable MSR (Model Specific Registers) for CPU power monitoring
  # Required for MangoHud and other tools to read CPU power consumption
  boot.kernelModules = [ "msr" ];

  # Make RAPL energy files readable for MangoHud CPU power display
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl*/*/energy_uj 0444 root root -"
  ];
}
