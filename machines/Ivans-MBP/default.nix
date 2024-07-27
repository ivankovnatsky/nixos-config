{
  imports = [
    ../../system/darwin.nix
  ];
  networking.hostName = "Ivans-MBP";
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
    ];
    casks = [
    ];
    masApps = { };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
