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

  # Don't let NetworkManager bring up the roaming USB-eth dongle on a3.
  # When it joins 192.168.50.0/24 alongside eno1 and wlp9s0, replies leave
  # via the lowest-metric default route (the dongle) and break return paths
  # for traffic destined to .50.6 / .50.11.
  networking.networkmanager.unmanaged = [
    "mac:f8:e4:3b:a7:0e:53"
  ];

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
