{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew.taps = [
    "boz/repo"
  ];

  # Remove /opt/homebrew/etc/tor/torrc.sample to make the tor work
  # Configure your application to use SOCKS in its proxy settings directly
  # localhost:9050
  homebrew.brews = [
    "tor"
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
