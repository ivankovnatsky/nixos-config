{ pkgs, ... }:

pkgs.writeShellScriptBin "settings" ''
  exec ${pkgs.python3}/bin/python ${./settings.py} "$@"
''
