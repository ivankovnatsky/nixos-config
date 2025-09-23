{ pkgs, ... }:

let
  freeze-window-lua = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/occivink/mpv-image-viewer/refs/heads/master/scripts/freeze-window.lua";
    sha256 = "sha256-33doEp13UC4xFjaaeRyweV0Rk5LTIE3JtChmDUepJsI=";
  };
in
{
  home.packages = with pkgs; [
    mpv
  ];

  # TODO: Check mpv scripts package.
  home.file.".config/mpv/config".text = ''
    # Do not show video window when playing audio
    no-audio-display
    save-position-on-quit=yes
    fs=no

    # When viewing images
    image-display-duration=5

    alang=eng
    force-seekable=yes
    audio-channels=2

    slang=eng
    sub-scale=0.5

    # Keep subtitles visible longer (in seconds, 0 = forever)
    # Default is usually around 7 seconds
    sub-duration=0

    # OnScreen Controller at the bottom, terriable UI, disable it.
    osc=no

    # https://mpv.io/manual/master/#options-osd-level
    osd-level=3

    no-border

    ytdl-format="bestvideo[height<=1080]+bestaudio/best"

    auto-window-resize=no
    keep-open=no

    keepaspect-window=no
    autofit-larger=100%x100%

    # Prevent window from floating on top
    ontop=no
  '';

  home.file = {
    ".config/mpv/scripts/freeze-window.lua".source = freeze-window-lua;
    ".config/mpv/input.conf".text = ''
      LEFT seek -3
      RIGHT seek 3
      UP seek 30
      DOWN seek -30
    '';
  };
}
