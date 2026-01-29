{ pkgs }:

pkgs.writeShellScriptBin "beszel-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./beszel-mgmt.py} "$@"
''
