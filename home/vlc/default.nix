{ ... }:

{
  # delta home/vlc/vlcrc ~/Library/Preferences/org.videolan.vlc/vlcrc
  #
  # VLC source references (~/Sources/code.videolan.org/videolan/vlc):
  # - audio-language, sub-language: src/libvlc-module.c:661-668
  #   "comma separated, two or three letter ISO-639 country code"
  # - macosx-continue-playback: modules/gui/macosx/main/macosx.m:122-126
  #   0 = Ask, 1 = Always, 2 = Never
  # - keybindings: src/libvlc-module.c:2574+ (key-toggle-fullscreen, key-audio-track, etc.)
  home.file."Library/Preferences/org.videolan.vlc/vlcrc".source = ./vlcrc;
}
