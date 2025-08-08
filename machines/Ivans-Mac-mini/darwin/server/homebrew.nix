{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
      "ollama"
    ];
    casks = [
      "stats"
    ];
  };
}
