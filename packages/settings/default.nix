{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "settings" ''
  exec ${python}/bin/python ${./settings.py} "$@"
''
