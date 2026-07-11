{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "direnv"
      "displayplacer"
      "mpv"
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
      "zapp"
    ];
    casks = [
      "firefox@developer-edition"
      "bitwarden"
      "coconutbattery"
      "hammerspoon"
      "whatsapp"
      {
        name = "kitty@nightly";
        greedy = true;
      }
      {
        name = "obsidian";
        greedy = true;
      }
    ];
    masApps = {
      "Numbers" = 361304891;
    };
  };
}
