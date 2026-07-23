{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    # Installed via Homebrew cask (firefox@developer-edition).
    package = null;

    profiles."default" = {
      id = 0;
      isDefault = true;
      settings = import ./firefox.nix;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        darkreader
      ];
    };
  };
}
