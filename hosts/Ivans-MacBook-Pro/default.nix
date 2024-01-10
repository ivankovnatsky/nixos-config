{ pkgs, ... }:

{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew = {
    casks = [
      "kitty"
      "chromium"
      "mos"
      "rectangle"
      "stats"
      "orbstack"
      "protonvpn"
      "teamviewer"
      "vlc"
    ];

    caskArgs = {
      no_quarantine = true;
    };

    masApps = {
      "1Password for Safari" = 1569813296;
      "Dark Reader for Safari" = 1438243180;
      "Bitwarden" = 1352778147;
    };
  };

  nixpkgs.overlays = [
    (
      self: super: {
        # terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
        #   name = "terraform";
        #   version = "1.1.7";
        #   sha256 = "sha256-iRnO7jT2v7Fqbp/2HJX0BDw1xtcLId4n5aFTwZx+upw=";
        #   system = "aarch64-darwin";
        # };
        # terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
        #   name = "terraform";
        #   version = "1.3.7";
        #   sha256 = "sha256-AdVT2197TPBym3JeRAJkPv3liEsdq/XrgK8yjOXkR88=";
        #   system = "aarch64-darwin";
        # };
        aws-sso-cli = super.callPackage ../../overlays/aws-sso-cli.nix { };

        istioctl = self.callPackage ../../overlays/istioctl.nix {
          name = "istioctl";
          version = "1.17.6";
          platform = "osx-arm64";
          sha256 = "sha256-3DcNqhexJ50P2AeNlQnOfO5a3307lIDq0bDSaGB6+TI=";
        };
        kor = self.callPackage ../../overlays/kor.nix { };
        atuin = self.callPackage ../../overlays/atuin.nix {
          inherit (pkgs.darwin.apple_sdk.frameworks) AppKit Security SystemConfiguration;
        };
      }
    )
  ];
}
