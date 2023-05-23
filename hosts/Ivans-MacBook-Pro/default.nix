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
        kubectl-ktop = super.callPackage ../../overlays/kubectl-ktop.nix { };
        tfupdate = super.callPackage ../../overlays/tfupdate.nix { };
        terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
          name = "terraform";
          version = "1.1.7";
          sha256 = "sha256-iRnO7jT2v7Fqbp/2HJX0BDw1xtcLId4n5aFTwZx+upw=";
          system = "aarch64-darwin";
        };
      }
    )
  ];
}
