{ pkgs }:

pkgs.writeShellScriptBin "download-youtube" ''
  exec ${pkgs.python3}/bin/python3 ${./download-youtube.py} "$@"
''
