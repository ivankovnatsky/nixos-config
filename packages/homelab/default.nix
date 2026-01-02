{ pkgs }:

pkgs.writeShellApplication {
  name = "homelab";
  runtimeInputs = [
    pkgs.dns
    pkgs.uptime-kuma-mgmt
  ];
  text = ''
    exec ${pkgs.python3}/bin/python3 ${./homelab.py} "$@"
  '';
}
