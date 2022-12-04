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
    hwdec=yes
    opengl-pbo=yes
    osc=no
    osd-level=0
    save-position-on-quit=yes
    slang=eng
    ytdl-format=bestvideo+bestaudio/best
    image-display-duration=5
    vo=gpu
    profile=gpu-hq
    audio-channels=2
  '';
}
