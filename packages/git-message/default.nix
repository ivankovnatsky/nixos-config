{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "git-message" ''
  exec ${pkgs.python3}/bin/python ${./git-message.py} "$@"
''
