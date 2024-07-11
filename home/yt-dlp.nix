{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    yt-dlp
  ];

  home.file = {
    "${config.xdg.configHome}/yt-dlp/config".text = ''
      # Download videos in the best HD format available
      -f "best[height<=1080]"
    '';
  };
}
