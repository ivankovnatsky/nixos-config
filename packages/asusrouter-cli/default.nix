{ pkgs }:

pkgs.writeShellScriptBin "asusrouter-cli" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.asusrouter
      ps.click
    ])
  }/bin/python ${./asusrouter-cli.py} "$@"
''
