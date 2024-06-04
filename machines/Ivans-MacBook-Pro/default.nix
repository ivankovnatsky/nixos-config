{
  imports = [
    ../../system/darwin.nix
  ];
  networking.hostName = "Ivans-MacBook-Pro";
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
    ];
    casks = [
      "whisky"
    ];
    masApps = {
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
