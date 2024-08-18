{ pkgs, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../modules/darwin/pam
    ../../modules/darwin/dock

    ../../modules/secrets
  ];
  networking.hostName = "Ivans-MBP";
  flags = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };
  security.pamCustom.enableSudoTouchIdAuth = true;
  system = {
    defaults = {
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
      };
    };
  };
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];
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
      "firefox"
      "orbstack"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "Okta Verify" = 490179405;
    };
    caskArgs = {
      no_quarantine = true;
    };
  };
  local = {
    dock.enable = true;
    dock.entries = [
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Calendar.app"; }
      { path = "/System/Applications/Reminders.app"; }
      { path = "/System/Applications/Notes.app"; }
      { path = "/System/Applications/App Store.app"; }
      { path = "/System/Applications/System Settings.app"; }
    ];
  };

  nixpkgs.overlays = [
    (
      self: super: { }
    )
  ];
}
