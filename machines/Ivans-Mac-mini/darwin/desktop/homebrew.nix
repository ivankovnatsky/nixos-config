{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
    ];
    casks = [
      "amethyst"
      "bitwarden"
      "chromium"
      "cursor"
      "firefox@developer-edition"
      "ghostty"
      "hammerspoon"
      "keycastr"
      "mos"
      # "mullvadvpn"
      "stats"
      "windsurf"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Bitwarden" = 1352778147;
      "Dark Reader for Safari" = 1438243180;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
