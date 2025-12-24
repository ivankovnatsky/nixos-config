{ pkgs, ... }:

pkgs.writeShellScriptBin "switch-menubar" ''
  exec ${pkgs.python3}/bin/python ${./switch-menubar.py} "$@"
''
