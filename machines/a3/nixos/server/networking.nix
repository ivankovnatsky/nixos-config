{
  # Networking configuration for a3 machine
  # Includes mDNS/Avahi setup for .local hostname resolution

  # Enable services for network discovery and hostname resolution
  services = {
    # Enable Avahi for .local hostname resolution (mDNS/Bonjour)
    avahi = {
      enable = true;
      nssmdns4 = true; # Enable .local hostname resolution via mDNS for IPv4
      nssmdns6 = true; # Enable .local hostname resolution via mDNS for IPv6
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
      # Allow discovery of services on the network
      openFirewall = true;
    };
  };

  # Note: NSS modules for .local resolution are automatically configured
  # when services.avahi.nssmdns4 is enabled

  # Network firewall configuration for mDNS
  networking.firewall = {
    allowedUDPPorts = [
      5353 # mDNS/Avahi
    ];
  };

  # a3's eno1 and wlp9s0 are both on 192.168.50.0/24. Without this, ARP flux
  # lets either NIC answer for any local IP — LAN clients learn the wrong
  # MAC for .50.6 and packets get black-holed by rp_filter.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
    "net.ipv4.conf.default.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_announce" = 2;
  };
}
