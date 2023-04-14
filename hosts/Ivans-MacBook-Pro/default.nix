{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew.taps = [
    "boz/repo"
  ];

  homebrew.brews = [
  ];

  homebrew.casks = [
    "chromium"
    "mos"
    "rectangle"
    "stats"
  ];

  homebrew.caskArgs = {
    no_quarantine = true;
  };

  nixpkgs.overlays = [
    (
      self: super: {
        eks-node-viewer = super.callPackage ../../overlays/eks-node-viewer.nix { };
        pv-migrate = super.callPackage ../../overlays/pv-migrate.nix { };
        granted = super.callPackage ../../overlays/granted.nix { };
        kubectl-ktop = super.callPackage ../../overlays/kubectl-ktop.nix { };
      }
    )
  ];
}
