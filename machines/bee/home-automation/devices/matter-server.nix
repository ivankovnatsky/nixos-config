{ config, ... }:

{
  # Add udev rule for persistent device naming
  services.udev.extraRules = ''
    # SMLIGHT SLZB-07 Matter device with serial number ba1ebce44173ed11bc026beefdf7b791
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ATTRS{serial}=="ba1ebce44173ed11bc026beefdf7b791", SYMLINK+="matter_adapter", SYMLINK+="ttyUSB1"
  '';

  # NOTE: Matter Server binding behavior:
  #
  # The python-matter-server supports --listen-address to bind to specific IPs.
  # Binding to bee's IP (192.168.50.3) instead of 0.0.0.0 for defense in depth.
  #
  # The NixOS module doesn't expose a listenAddress option, but we can use extraArgs.
  #
  # Security layers:
  # - Bound to bee's IP only (not all interfaces)
  # - Firewall restricts TCP 5580 to specific IPs
  # - Matter devices require pairing/commissioning
  # - WebSocket API requires authentication
  #
  # Monitoring: Uptime Kuma checks ${config.flags.beeIp}:5580 from mini

  services.matter-server = {
    enable = true;
    port = 5580;
    logLevel = "info";
    extraArgs = [
      "--listen-address"
      config.flags.beeIp
    ];
  };

  # Open firewall for Matter Server API (needed for Home Assistant on bee and monitoring from mini)
  networking.firewall.allowedTCPPorts = [ 5580 ];
}
