{ pkgs, ... }:
{
  home = {
    packages = [ pkgs.pgcli ];
    file.".config/pgcli/config".text = ''
      [main]
      # Enable Vi mode for keybindings
      vi = True
    '';
  };
}
