{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.bat ];

  # Manual configuration file for bat
  home.file.".config/bat/config".text = ''
    # Use Dracula theme for dark mode (default)
    --theme-dark="Dracula"

    # Use GitHub theme for light mode
    --theme-light="GitHub"
  '';

  home.activation.batCacheClear = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.bat}/bin/bat --list-themes 2>&1 | grep -q "bat cache --clear"; then
      run rm -rf "$HOME/.cache/bat"
    fi
  '';
}
