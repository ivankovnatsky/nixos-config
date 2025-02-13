{ pkgs, ... }:
{
  home.packages = [ pkgs.bat ];

  # Manual configuration file for bat
  home.file.".config/bat/config".text = ''
    # Use Dracula theme for dark mode (default)
    --theme-dark="Dracula"

    # Use GitHub theme for light mode
    --theme-light="GitHub"
  '';
}
