{ pkgs }:

pkgs.writeShellScriptBin "notes" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.click
    ])
  }/bin/python ${./notes.py} "$@"
''
