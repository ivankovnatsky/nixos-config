{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
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
