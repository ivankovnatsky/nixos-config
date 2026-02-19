{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nixpkgs-darwin-master-ytdlp.yt-dlp
  ];

  home.file = {
    "${config.xdg.configHome}/yt-dlp/config".text = ''
      -S "res:1080"
    '';
  };
}
