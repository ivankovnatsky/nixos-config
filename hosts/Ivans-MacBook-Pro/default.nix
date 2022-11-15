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
    "chromium"
    "teamviewer"
    "stats"
  ];

  homebrew.caskArgs = {
    no_quarantine = true;
  };
}
