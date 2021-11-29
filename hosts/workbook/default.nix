{
  homebrew.taps = [
    "fabianishere/personal"
  ];

  homebrew.brews = [
    "pam_reattach"
    "awscli"
  ];

  homebrew.casks = [
    "aws-vpn-client"
  ];

  nixpkgs.overlays = [
    inputs.self.overlay
  ];

  security.pam.enableSudoTouchIdAuth = true;
}
