{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew.taps = [
    "boz/repo"
  ];

  homebrew.brews = [
    "kail"
  ];

  homebrew.casks = [
    "teamviewer"
  ];
}
