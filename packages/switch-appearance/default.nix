{ pkgs, ... }:

pkgs.writeShellScriptBin "switch-appearance" ''
  exec ${pkgs.python3}/bin/python ${./switch-appearance.py} "$@"
''
