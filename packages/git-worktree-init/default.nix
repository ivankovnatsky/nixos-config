{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-init" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./git-worktree-init.py} "$@"
''
