{ pkgs }:

pkgs.writeShellScriptBin "syncthing-cleaner" ''
  exec ${pkgs.python3}/bin/python ${./syncthing-cleaner.py} "$@"
''
