{
  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-fonts"
    "homebrew/core"
  ];

  homebrew.casks = [
    "alacritty"
    "amethyst"
    "firefox"
    "font-hack-nerd-font"
    "google-chrome"
    "hammerspoon"
  ];
}
