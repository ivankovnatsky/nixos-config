{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "jellyfin-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./jellyfin-mgmt.py} "$@"
''
