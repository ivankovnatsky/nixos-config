{ pkgs }:

pkgs.writeShellScriptBin "tmux-spawn" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./tmux-spawn.py} "$@"
''
