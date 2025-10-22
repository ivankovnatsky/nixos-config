{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "ollama"
    ];
    casks = [
      "mos"
    ];
    caskArgs = {
      no_quarantine = true;
    };
  };
}
