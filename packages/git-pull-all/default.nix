{ pkgs }:

pkgs.writeShellScriptBin "git-pull-all" ''
  exec ${pkgs.python3}/bin/python3 ${./git-pull-all.py} "$@"
''
