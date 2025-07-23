{ config, lib, pkgs, ... }:

{
  home.file.".config/tweety/config.json".text = builtins.toJSON {
    command = "${pkgs.fish}/bin/fish";
    args = [ "--login" ];
    editor = "nvim";
    env = {};
    xterm = {
      fontFamily = config.flags.fontGeneral;
      fontSize = 14;
      cursorBlink = false;
      cursorStyle = "block";
      theme = {
        background = "#1e1e1e";
        foreground = "#d4d4d4";
      };
      allowTransparency = false;
      scrollback = 10000;
      tabStopWidth = 4;
    };
    theme = "Tomorrow";
    themeDark = "Tomorrow Night";
  };
}
