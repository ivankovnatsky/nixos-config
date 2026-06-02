{
  ...
}:

{
  boot.kernelModules = [
    "thunderbolt"
    "typec_ucsi"
    "ucsi_acpi"
  ];

  # NixOS doesn't auto-authorize TB devices; without this the CalDigit dock's
  # PCIe tunneling (display, ethernet) never activates even with modules loaded.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTRS{iommu_dma_protection}=="1", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';
}
