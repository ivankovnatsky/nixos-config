{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
    };
    global.brewfile = true;
    brews = [
      "ffmpeg"
      "make"
      "tmux"
      "git"
    ];
  };
}
