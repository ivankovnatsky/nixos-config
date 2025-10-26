{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "syncthing-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ps.bcrypt ])}/bin/python ${./syncthing-mgmt.py} "$@"
''
