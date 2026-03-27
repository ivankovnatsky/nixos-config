# Darwin-compatible navidrome overlay
# Nixpkgs marks navidrome as broken on Darwin due to sandbox serialization
# limits, not an actual build issue.
{ navidrome }:

navidrome.overrideAttrs (old: {
  meta = old.meta // {
    broken = false;
  };
})
