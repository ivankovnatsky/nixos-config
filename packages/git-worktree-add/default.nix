{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-add" ''
  exec ${pkgs.fish}/bin/fish ${./git-worktree-add.fish} "$@"
''
