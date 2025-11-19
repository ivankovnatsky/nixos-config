{ ... }:

{
  # Enable MSR (Model Specific Registers) for CPU power monitoring
  # Required for MangoHud and other tools to read CPU power consumption
  boot.kernelModules = [ "msr" ];
}
