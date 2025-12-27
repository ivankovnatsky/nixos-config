{ pkgs }:

pkgs.writeShellScriptBin "poweron-homelab" ''
  exec ${pkgs.python3}/bin/python3 ${./poweron-homelab.py} "$@"
''
