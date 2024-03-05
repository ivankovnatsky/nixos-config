{ ... }:

{
  imports = [
    ./configuration.nix

    ../../modules/secrets.nix
  ];

  # Syncthing
  # Ports are not open by default and I want to sync my config easily between
  # machines, as I would edit my configs mostly on host machine.
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
