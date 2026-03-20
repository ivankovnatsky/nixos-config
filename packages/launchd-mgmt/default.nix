{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "launchd-mgmt" ''
  exec ${python}/bin/python ${./launchd-mgmt.py} "$@"
''
