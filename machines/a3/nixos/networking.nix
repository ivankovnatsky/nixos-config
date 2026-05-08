{
  # Networking configuration for a3 machine
  # Includes mDNS/Avahi setup for .local hostname resolution

  # Static DNS via Cloudflare. NextDNS module (./nextdns-resolved.nix) is
  # commented out in default.nix; flip back if NextDNS profile resolution
  # is needed again.
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  # Enable services for network discovery and hostname resolution
  services = {
    resolved.enable = true;

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
}
