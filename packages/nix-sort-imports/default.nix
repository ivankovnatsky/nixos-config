{ pkgs }:

pkgs.writeShellScriptBin "nix-sort-imports" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./nix-sort-imports.py} "$@"
''
