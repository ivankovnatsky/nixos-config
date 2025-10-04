{
  config,
  lib,
  pkgs,
  ...
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

  # Add static route to link-local network for devices that fall back to APIPA
  # This allows connectivity to Elgato Key Light when routers are powered off
  # Using systemd service with delay to ensure network is completely ready
  # https://discourse.nixos.org/t/networking-interfaces-name-ipv4-routes-not-working/13648/4
  systemd.services.add-link-local-route = {
    description = "Add route to link-local network for IoT devices";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "systemd-networkd.service"
      "NetworkManager.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Add a delay to ensure the network is completely ready
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.iproute2}/bin/ip route add 169.254.0.0/16 dev enp1s0 scope link metric 1000 || true'";
    };
  };
}
