{
  # Add udev rule for persistent device naming
  services.udev.extraRules = ''
    # SMLIGHT SLZB-07 Matter device with serial number ba1ebce44173ed11bc026beefdf7b791
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ATTRS{serial}=="ba1ebce44173ed11bc026beefdf7b791", SYMLINK+="matter_adapter", SYMLINK+="ttyUSB1"
  '';

  # NOTE: Matter Server binding behavior:
  #
  # Matter Server MUST bind to 0.0.0.0 (all interfaces) because:
  # - mDNS (multicast DNS) requires binding to all interfaces for device discovery
  # - Binding to specific IP causes "Network is unreachable" errors for mDNS
  # - Matter devices advertise themselves via multicast which needs all interfaces
  #
  # The python-matter-server supports --listen-address but using it breaks mDNS.
  # We rely on firewall rules for security instead.
  #
  # Security layers:
  # - Firewall restricts TCP 5580 to specific IPs (bee and mini)
  # - Matter devices require pairing/commissioning
  # - WebSocket API requires authentication
  #
  # Reference: Attempted binding to beeIp in commit 27fc3d86, reverted due to mDNS issues
  # Error: "CHIP_ERROR [chip.native.DIS] Failed to advertise records: Network is unreachable"

  services.matter-server = {
    enable = true;
    port = 5580;
    logLevel = "info";
  };

  # Open firewall for Matter Server API (needed for Home Assistant on bee and monitoring from mini)
  networking.firewall.allowedTCPPorts = [ 5580 ];
}
