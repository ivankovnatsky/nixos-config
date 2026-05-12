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
      "forgejo"
      "navidrome"
    ];
    casks = [
      "jellyfin"
    ];
  };
}
