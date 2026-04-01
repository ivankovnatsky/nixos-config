{ pkgs }:

pkgs.writeShellScriptBin "git-restore" ''
  exec ${pkgs.python3}/bin/python ${./git-restore.py} "$@"
''
