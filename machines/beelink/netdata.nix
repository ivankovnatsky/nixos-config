{
  # Enable the Netdata service with default settings
  services.netdata = {
    enable = true;
  };

  # Open firewall port for Netdata web interface
  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
  };
}
