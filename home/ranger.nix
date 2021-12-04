{ pkgs, ... }:

{
  home.packages = [ pkgs.ranger ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };
  };
}
