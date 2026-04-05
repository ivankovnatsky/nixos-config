{ pkgs }:

pkgs.writeShellApplication {
  name = "homelab";
  runtimeInputs = [
    pkgs.dns
    pkgs.uptime-kuma-mgmt
  ];
  text = ''
    exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./homelab.py} "$@"
  '';
}
