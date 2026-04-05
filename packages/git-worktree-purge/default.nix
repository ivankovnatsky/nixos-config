{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-purge" ''
  exec ${pkgs.python3}/bin/python ${./git-worktree-purge.py} "$@"
''
