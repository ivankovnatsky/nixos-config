{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/pam
    ../../system/darwin.nix
  ];
  users.users.ivan.home = "/Users/ivan";
  networking.hostName = "Ivans-MacBook-Pro";
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "vim";
    darkMode = false;
  };
  security.pamCustom.enableSudoTouchIdAuth = true;
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
    ];
    masApps = { };
    caskArgs = {
      no_quarantine = true;
    };
  };
  fonts.packages = with pkgs; [
    nerd-fonts.hack
  ];
}
