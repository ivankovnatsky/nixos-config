{ pkgs }:

pkgs.writeShellScriptBin "diff-deep" ''
  EXCLUDES=(
    .claude
    .DS_Store
    .git
    .rumdl_cache
    .stfolder
    .terraform
    .terraform.lock.hcl
    "terraform.tfstate*"
    "workspace*"
  )

  EXCLUDE_ARGS=""
  for e in "''${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$e"
  done

  ${pkgs.diffutils}/bin/diff -ru $EXCLUDE_ARGS "$@" | ${pkgs.delta}/bin/delta
''
