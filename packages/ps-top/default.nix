{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.psutil ]);
in
pkgs.writeShellScriptBin "ps-top" ''
  exec ${python}/bin/python3 ${./ps-top.py} "$@"
''
