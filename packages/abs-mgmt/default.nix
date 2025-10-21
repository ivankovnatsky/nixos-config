{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "abs-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./abs-mgmt.py} "$@"
''
