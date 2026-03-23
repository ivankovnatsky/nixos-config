{ pkgs }:

pkgs.writeShellScriptBin "forgejo-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./forgejo-mgmt.py} "$@"
''
