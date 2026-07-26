{ ... }:

{
  # anker-monitor serve (home-manager user service) binds 0.0.0.0:8787 so the
  # Mac mini can poll SOC over the LAN. The home module can't touch the system
  # firewall, so open the port here.
  networking.firewall.allowedTCPPorts = [ 8787 ];
}
