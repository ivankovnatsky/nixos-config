{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      # CLI tool to configure display resolutions and arrangements
      "displayplacer"
      # Since nix places it's new installs under newly generated nix store
      # path, we can't rely on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
    ];
    # Installed or managed using Kandji
    # google-chrome
    # zoom
    casks = [
      "amethyst"
      "chromium"
      "dbeaver-community"
      "hammerspoon"
      "keycastr"
      "mos"
      "stats"
      "twingate"
      "vivaldi"
    ];
    masApps = {
      # Installed using Kandji
      # "Okta Verify" = 490179405;
      # "Slack for Desktop" = 803453959;
      # "Okta Extension App" = 1439967473;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
