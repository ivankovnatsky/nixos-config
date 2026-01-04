{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "antoniorodr/homebrew-memo/memo"
      "keith/homebrew-formulae/reminders-cli"
      "ollama"
      "xwmx/homebrew-taps/notes-app"
    ];
    casks = [
      "mos"
    ];
    caskArgs = {
      no_quarantine = true;
    };
  };
}
