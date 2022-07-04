{ config, pkgs, ... }:

let
  fontSize = 10.7;

in
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        font = "${builtins.toString config.variables.fontMono}:size=${builtins.toString fontSize}";
        dpi-aware = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };

    };
  };
}
