{ pkgs }:

pkgs.writeShellScriptBin "abs-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.click
    ])
  }/bin/python ${./abs-mgmt.py} "$@"
''
