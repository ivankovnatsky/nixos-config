{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    casks = [
      "amethyst"
      "cursor"
      "firefox"
      "ghostty"
      "hammerspoon"
      "kitty"
      "mullvadvpn"
      "vivaldi"
      "windsurf"
    ];
    # masApps = {
    #   "Dark Reader for Safari" = 1438243180;
    #   "Numbers" = 409203825;
    # };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
