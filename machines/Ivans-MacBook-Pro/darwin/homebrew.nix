{ pkgs, ... }:
{
  # MacBook Pro specific MAS apps only
  # Base homebrew configuration comes from ../../darwin/homebrew.nix
  homebrew = {
    brews = [
      "displayplacer"
    ];
    casks = [
      # Needed to `brew uninstall --cask ghostty kitty`
      {
        name = "ghostty@tip";
        greedy = true;
      }
      {
        name = "kitty@nightly";
        greedy = true;
      }
      "mullvad-vpn"
    ];
    masApps = {
    "Xcode" = 497799835;
    };
  };
}
