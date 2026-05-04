{ pkgs, ... }:

let
  src = ./.;
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "notifications" ''
  exec ${python}/bin/python ${src}/notifications.py "$@"
''
