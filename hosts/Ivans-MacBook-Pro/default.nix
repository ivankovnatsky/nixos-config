{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew.taps = [
    "boz/repo"
  ];

  homebrew.brews = [
    "kail"
    "youtube-dl"
  ];

  homebrew.casks = [
    "teamviewer"
    "stats"
  ];
}
