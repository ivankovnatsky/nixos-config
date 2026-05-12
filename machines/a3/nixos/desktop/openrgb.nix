# OpenRGB — control / disable RGB lighting on GPU and other devices.
#
# Status (2026-05): DISABLED — placeholder only.
#
# nixpkgs module: services.hardware.openrgb
#   nixos/modules/services/hardware/openrgb.nix
#   Options:
#     - enable
#     - package
#     - motherboard         # auto-detects "amd" from cpu.amd.updateMicrocode
#     - server.port         # default 6742
#     - startupProfile      # name of profile file in /var/lib/OpenRGB
#
# Hardware on a3:
#   - GPU: ASUS RTX 5080 (PCI subsystem 1043:89de — TUF or ROG variant)
#   - Motherboard: AMD (Ryzen 7 9800X3D)
#
# Why this is a placeholder:
#   ASUS RTX 50-series cards are NOT yet supported by OpenRGB. Driver work
#   is tracked in these GitLab issues — once one of them lands, enable the
#   module, capture an "all off" profile via the GUI, save it under
#   /var/lib/OpenRGB, and point startupProfile at it.
#
#   - ASUS TUF Gaming RTX 5080:
#       https://gitlab.com/CalcProgrammer1/OpenRGB/-/issues/4703
#   - ASUS ROG Astral RTX 5080:
#       https://gitlab.com/CalcProgrammer1/OpenRGB/-/issues/4644
#   - Supported devices list:
#       https://openrgb.org/devices.html
#
# To enable later, uncomment the block below and add `./openrgb.nix` to
# machines/a3/nixos/desktop/default.nix imports.

{ ... }:
{
  # services.hardware.openrgb = {
  #   enable = true;
  #   # motherboard = "amd";  # auto-detected
  #   startupProfile = "off";  # save a profile named "off" via the GUI first
  # };
}
