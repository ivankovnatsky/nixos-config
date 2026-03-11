{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "obs" ''
  exec ${python}/bin/python3 ${./obs.py} "$@"
''
