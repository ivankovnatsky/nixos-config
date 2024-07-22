{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mpv
  ];

  home.file.".config/mpv/config".text = ''
    # Do not show video window when playing audio
    no-audio-display
    alang=eng
    force-seekable=yes
    audio-channels=2

    fs=no
    osc=no
    osd-level=1  # Default osd-level when not seeking
    no-border
    # When viewing images
    image-display-duration=5
    ytdl-format="bestvideo[height<=1080]+bestaudio/best"
    keepaspect-window=no
    autofit-larger=100%x100%

    save-position-on-quit=yes
    slang=eng
    sub-scale=0.5
  '';
}
