{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "keith/homebrew-formulae/reminders-cli"
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
