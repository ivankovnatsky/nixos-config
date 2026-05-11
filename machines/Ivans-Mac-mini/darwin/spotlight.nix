{
  # Spotlight on `/nix` is pure waste — the store is immutable and never
  # user-searched, but the index can grow to >1G under `.Spotlight-V100`.
  # `mdutil -i off /nix` returns "unknown indexing state" (Spotlight does not
  # track the volume), so use the documented `.metadata_never_index` marker
  # file at the volume root instead — Spotlight respects it unconditionally
  # and it survives reboots.
  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight on /nix... "
    touch /nix/.metadata_never_index
    rm -rf /nix/.Spotlight-V100
    echo "ok"
  '';
}
