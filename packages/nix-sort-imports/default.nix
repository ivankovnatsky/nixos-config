{ pkgs }:

pkgs.writeShellScriptBin "nix-sort-imports" ''
  exec ${pkgs.python3}/bin/python ${./nix-sort-imports.py} "$@"
''
