{ pkgs, ... }:

pkgs.writeShellScriptBin "switch-appearance-py" ''
  exec ${pkgs.python3}/bin/python ${./switch-appearance.py} "$@"
''
