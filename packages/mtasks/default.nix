{ pkgs }:

pkgs.writeShellScriptBin "mtasks" ''
  exec ${pkgs.python3.withPackages (ps: [
    ps.click
    ps.rich
  ])}/bin/python3 ${./mtasks.py} "$@"
''
