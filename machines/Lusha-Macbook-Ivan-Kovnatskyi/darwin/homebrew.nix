{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.cleanup = "zap";
    global.brewfile = true;
    brews = [
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
      "bitwarden"
      "chatgpt"
      "claude"
      "cursor"
      "dbeaver-community"
      "ghostty"
      "hammerspoon"
      "mindmac"
      "orbstack"
      "twingate"
      "windsurf"
    ];
    # FIXME: Some weird re-installation happening
    # Re-enable with brew taps update:
    # https://github.com/zhaofengli/nix-homebrew/issues/74#issuecomment-2807640949
    #
    # ```console
    # Using windsurf
    # Installing Dark Reader for Safari
    # Installing Numbers
    # Error: Download failed: The installation could not be started.
    # Installing Numbers has failed!
    # `brew bundle` failed! 1 Brewfile dependency failed to install
    # ```
    # masApps = {
    #   # Installed using Kandji
    #   # "Okta Verify" = 490179405;
    #   # "Slack for Desktop" = 803453959;
    #   "Dark Reader for Safari" = 1438243180;
    #   "Okta Extension App" = 1439967473;
    # };
    caskArgs = {
      no_quarantine = true;
    };
  };
}
