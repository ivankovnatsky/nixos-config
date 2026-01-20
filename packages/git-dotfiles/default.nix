{ pkgs }:

pkgs.writeShellScriptBin "git-dotfiles" ''
  exec ${pkgs.python3}/bin/python ${./git-dotfiles.py} "$@"
''
