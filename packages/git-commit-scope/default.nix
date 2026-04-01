{ pkgs }:

pkgs.writeShellScriptBin "git-commit-scope" ''
  exec ${pkgs.python3}/bin/python ${./git-commit-scope.py} "$@"
''
