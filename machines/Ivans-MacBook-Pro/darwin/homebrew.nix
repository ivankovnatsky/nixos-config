{ pkgs, ... }:
{
  # MacBook Pro specific MAS apps only
  # Base homebrew configuration comes from ../../darwin/homebrew.nix
  homebrew = {
    brews = [
      "displayplacer"
    ];
    casks = [
      "mullvad-vpn"
    ];
    masApps = {
    "Xcode" = 497799835;
    };
  };
}
