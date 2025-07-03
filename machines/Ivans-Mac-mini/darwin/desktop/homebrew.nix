{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    casks = [
      "amethyst"
      "bitwarden"
      "chromium"
      "cursor"
      "discord"
      "firefox"
      "ghostty"
      "hammerspoon"
      "keycastr"
      "mos"
      "nvidia-geforce-now"
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
