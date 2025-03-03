{
  nix = {
    extraOptions = ''
      auto-optimise-store = true
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
      warn-dirty = false
      accept-flake-config = true
    '';
  };
}
