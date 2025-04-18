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
      "bitwarden"
      "cursor"
      "firefox"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "kitty"
      "mullvadvpn"
      "silicon-labs-vcp-driver"
      "vivaldi"
      "windsurf"
    ];
    # Re-enable with brew taps update:
    # https://github.com/zhaofengli/nix-homebrew/issues/74#issuecomment-2807640949
    # masApps = {
    #   "Numbers" = 409203825;
    #   "Pages" = 409201541;
    #   "Bitwarden" = 1352778147;
    #   "Dark Reader for Safari" = 1438243180;
    # };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
