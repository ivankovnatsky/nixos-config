{
  imports = [
    ./configuration.nix
  ];

  networking.firewall.allowedTCPPorts = [ 8384 ];
}
