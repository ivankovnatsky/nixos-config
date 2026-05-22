{ ... }:

{
  # NixOS-side companion to the miniserve file server, which itself runs as a
  # home-manager user systemd unit (machines/a3/home/server/miniserve.nix).
  #
  # That home-manager module can't touch the system firewall, so the inbound
  # port miniserve binds (0.0.0.0:8080, [::]:8080) must be opened here or the
  # NixOS firewall silently drops LAN connections to it.
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
