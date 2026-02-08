{ pkgs }:

pkgs.writeShellScriptBin "dotfiles" ''
  exec ${pkgs.python3}/bin/python ${./dotfiles.py} "$@"
''
