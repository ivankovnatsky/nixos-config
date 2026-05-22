{ pkgs }:

pkgs.writeShellScriptBin "tasks" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.click
      ps.rich
    ])
  }/bin/python3 ${./tasks.py} "$@"
''
