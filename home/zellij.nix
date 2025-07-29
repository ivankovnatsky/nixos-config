{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # zesh
  ];
  
  programs.zellij = {
    enable = true;
    
    settings = {
      # pane_frames = false;
      # simplified_ui = true;
    };
  };
}
