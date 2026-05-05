{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "git-commit-scope" ''
  exec ${python}/bin/python ${src}/git-commit-scope.py "$@"
''
