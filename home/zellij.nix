{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # zesh
  ];
  
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    
    settings = {
      theme = "default";
      default_shell = "fish";
      pane_frames = false;
      simplified_ui = true;
    };
  };
}
