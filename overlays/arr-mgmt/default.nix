{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "arr-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./arr-mgmt.py} "$@"
''
