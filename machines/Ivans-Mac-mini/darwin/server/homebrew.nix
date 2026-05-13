{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "ffmpeg"
      "navidrome"
    ];
    casks = [
      "jellyfin"
    ];
  };
}
