{ pkgs }:

pkgs.writeShellScriptBin "diff-deep" ''
  EXCLUDES=(
    .git
    .obsidian
    .terraform
    "terraform.tfstate*"
    .terraform.lock.hcl
  )

  EXCLUDE_ARGS=""
  for e in "''${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$e"
  done

  ${pkgs.diffutils}/bin/diff -ru $EXCLUDE_ARGS "$@" | ${pkgs.delta}/bin/delta
''
