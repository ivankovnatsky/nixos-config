{ pkgs }:

pkgs.writeShellScriptBin "nix-find-orphans" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./nix-find-orphans.py} "$@"
''
