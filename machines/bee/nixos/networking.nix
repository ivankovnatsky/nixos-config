{ config
, lib
, pkgs
, ...
}:

{
  # Enable mDNS for local hostname resolution
  networking = {
    # Enable mDNS port in firewall
    firewall.allowedUDPPorts = [
      5353 # mDNS port for zeroconf/Avahi
      1900 # SSDP/UPnP discovery
    ];
  };

  # Enable Avahi for mDNS/DNS-SD service discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable multicast DNS NSS lookup
    # Configure Avahi to work alongside dnsmasq
    allowInterfaces = [
      "enp1s0"
    ];
    ipv4 = true;
    ipv6 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    # Add specific configuration for .local domains
    extraConfig = ''
      [reflector]
      enable-reflector=yes
      reflect-ipv=yes

      [server]
      allow-point-to-point=yes
      use-iff-running=yes
      disallow-other-stacks=no
    '';
  };

  # Update NSS configuration to use mDNS for hostname resolution
  system.nssDatabases.hosts = lib.mkBefore [
    "mdns4_minimal [NOTFOUND=return]"
    "mdns4"
  ];

  # Extend dnsmasq configuration to forward .local queries to Avahi
  services.dnsmasq.settings = lib.mkIf config.services.dnsmasq.enable {
    # Add mDNS server for .local domains (will be merged with existing server entries)
    server = lib.mkAfter [
      "/local/127.0.0.1#5353"
    ];
  };
}
