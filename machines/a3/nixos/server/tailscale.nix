{ config, pkgs, ... }:

{
  # 1. Enable the service and the firewall
  services.tailscale.enable = true;
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # 2. Enable IP forwarding so this machine can relay traffic
  # (required for subnet routes and exit nodes)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # 3. Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  # 4. Optimization: Prevent systemd from waiting for network online
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  # Do not let tailnet DNS override this host's local resolver. The tailnet
  # currently has a global nameserver of 192.168.50.1, which sends a3 back
  # through the router/Asus NextDNS profile instead of a3's own profile.
  services.tailscale.extraSetFlags = [
    "--accept-dns=false"
  ];

  # ```console
  # sudo tailscale set --advertise-routes=192.168.50.0/24
  # ```
}
