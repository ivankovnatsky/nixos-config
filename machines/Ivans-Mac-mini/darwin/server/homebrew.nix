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
      # Moved off the Nix store (was darwin/server/packages.nix):
      "make"
      "tmux"
      "git"
      "tailscale"
    ];
  };
}
