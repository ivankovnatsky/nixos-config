{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-purge" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./git-worktree-purge.py} "$@"
''
