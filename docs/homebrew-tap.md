# Local Homebrew Tap

Local Homebrew casks stored in the `Casks/` directory at the root of this
repository.

## Integration with nix-homebrew

This tap is integrated into the NixOS configuration via flake inputs and
nix-homebrew.

Add to `flake.nix` inputs:

```nix
ivankovnatsky-homebrew-tap = {
  url = "github:ivankovnatsky/nixos-config";
  flake = false;
};
```

Configure in `flake/machines/darwin.nix` taps:

```nix
taps = {
  "homebrew/homebrew-core" = inputs.homebrew-core;
  "homebrew/homebrew-cask" = inputs.homebrew-cask;
  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
  "ivankovnatsky/homebrew-tap" = inputs.ivankovnatsky-homebrew-tap;
};
```

Use in machine configuration:

```nix
homebrew.casks = [
  "ivankovnatsky/homebrew-tap/comet"
];
```

## Casks

- **comet** - Comet browser by Perplexity AI

## Maintenance

- The Comet download URL uses AWS signed URLs that expire periodically
- Update the URL in `Casks/comet.rb` when it expires
- `sha256 :no_check` is used due to changing signed URLs
