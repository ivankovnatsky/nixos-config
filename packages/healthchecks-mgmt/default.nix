{ pkgs }:

pkgs.writeShellScriptBin "healthchecks-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./healthchecks-mgmt.py} "$@"
''
