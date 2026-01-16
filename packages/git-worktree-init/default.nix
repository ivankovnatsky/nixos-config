{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-init" ''
  exec ${pkgs.python3}/bin/python ${./git-worktree-init.py} "$@"
''
