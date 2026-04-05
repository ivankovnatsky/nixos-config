{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "git-commit-scope" ''
  exec ${python}/bin/python ${./git-commit-scope.py} "$@"
''
