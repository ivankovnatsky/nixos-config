{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nixpkgs-master.yt-dlp
  ];

  home.file = {
    "${config.xdg.configHome}/yt-dlp/config".text = ''
      -S "res:1080"
    '';
  };
}
