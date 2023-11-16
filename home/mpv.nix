{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mpv
  ];

  home.file.".config/mpv/config".text = ''
    no-audio-display
    alang=eng
    force-seekable=yes
    fs=yes
    osc=no
    osd-level=1
    save-position-on-quit=yes
    slang=eng
    ytdl-format=bestvideo+bestaudio/best
    image-display-duration=5
    audio-channels=2
  '';
}
