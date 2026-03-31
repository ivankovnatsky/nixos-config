{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "displayplacer"
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    casks = [
      "amethyst"
      "bitwarden"
      "chromium"
      {
        name = "coconutbattery";
        greedy = true;
      }
      "firefox"
      "google-chrome"
      # Needed to `brew uninstall --cask ghostty kitty`
      {
        name = "ghostty@tip";
        greedy = true;
      }
      "hammerspoon"
      {
        name = "kitty@nightly";
        greedy = true;
      }
      "mac-mouse-fix"
      "silicon-labs-vcp-driver"
      "obsidian"
      "visual-studio-code"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Bitwarden" = 1352778147;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
