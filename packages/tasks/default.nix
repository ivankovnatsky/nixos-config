{ pkgs }:

pkgs.writeShellScriptBin "tasks" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.click
    ])
  }/bin/python3 ${./tasks.py} "$@"
''
