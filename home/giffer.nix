{ pkgs, ... }:

{
  home.packages = with pkgs; [
    giffer
    ffmpeg
  ];
}
