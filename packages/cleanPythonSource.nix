{ lib }:

# Filters out python build/cache artifacts so changes to .pyc files
# (and the like) don't invalidate the derivation hash.
src:
lib.cleanSourceWith {
  src = lib.cleanSource src;
  filter =
    name: type:
    let
      baseName = baseNameOf (toString name);
    in
    !(
      type == "directory"
      && (
        baseName == "__pycache__"
        || baseName == ".ruff_cache"
        || baseName == ".mypy_cache"
        || baseName == ".pytest_cache"
      )
    )
    && !(lib.hasSuffix ".pyc" baseName);
}
