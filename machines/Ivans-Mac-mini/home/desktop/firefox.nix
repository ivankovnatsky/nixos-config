{ ... }:
{
  programs.firefox = {
    enable = true;
    # Installed via Homebrew cask (firefox@developer-edition).
    package = null;

    profiles."default" = {
      id = 0;
      isDefault = true;
      settings = import ../../../../home/firefox.nix;
    };
  };
}
