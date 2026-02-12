{ pkgs }:

pkgs.writeShellScriptBin "claude-statusline" ''
  exec ${pkgs.python3}/bin/python ${./claude-statusline.py} "$@"
''
