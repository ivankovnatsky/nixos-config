{ pkgs }:

pkgs.writeShellScriptBin "giffer" ''
  exec ${pkgs.python3}/bin/python ${./giffer.py} "$@"
''
