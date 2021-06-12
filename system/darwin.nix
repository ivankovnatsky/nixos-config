{
  nixpkgs.overlays = [ (import ./overlays/darwin/default.nix) ];

  programs.zsh.enable = true; # default shell on catalina

  system = {
    defaults = {

      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        _HIHideMenuBar = true;
        NSAutomaticCapitalizationEnabled = false;
      };

      dock = {
        autohide = true;
        minimize-to-application = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = false;
      };

      loginwindow = {
        GuestEnabled = false;
      };
    };
  };

  system.stateVersion = 4;
}
