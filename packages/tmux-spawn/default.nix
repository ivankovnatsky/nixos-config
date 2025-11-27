{ pkgs }:

pkgs.writeShellScriptBin "tmux-spawn" ''
  exec ${pkgs.python3}/bin/python ${./tmux-spawn.py} "$@"
''
