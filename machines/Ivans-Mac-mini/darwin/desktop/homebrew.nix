{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
    ];
    casks = [
      "bitwarden"
      "chromium"
      "mos"
    ];
    masApps = {
      "Bitwarden" = 1352778147;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
