{
  # Add udev rule for persistent device naming
  services.udev.extraRules = ''
    # SMLIGHT SLZB-07 Matter device with serial number ba1ebce44173ed11bc026beefdf7b791
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ATTRS{serial}=="ba1ebce44173ed11bc026beefdf7b791", SYMLINK+="matter_adapter", SYMLINK+="ttyUSB1"
  '';

  services.matter-server = {
    enable = true;
    port = 5580; # Default port
    logLevel = "info"; # Default log level
    extraArgs = [ ];
  };
}
