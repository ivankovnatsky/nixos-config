{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew = {
    taps = [
      "boz/repo"
    ];

    casks = [
      "kitty"
      "chromium"
      "mos"
      "rectangle"
      "stats"
    ];

    caskArgs = {
      no_quarantine = true;
    };

    masApps = {
      "Slack for Desktop" = 803453959;
    };
  };

  nixpkgs.overlays = [
    (
      self: super: {
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
