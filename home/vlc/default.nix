{ lib, ... }:

{
  # delta home/vlc/vlcrc ~/Library/Preferences/org.videolan.vlc/vlcrc
  home.activation.vlcConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    vlcConfigDir="$HOME/Library/Preferences/org.videolan.vlc"
    mkdir -p "$vlcConfigDir"
    if [ ! -f "$vlcConfigDir/vlcrc" ] || diff -q ${./vlcrc} "$vlcConfigDir/vlcrc" >/dev/null 2>&1; then
      cp ${./vlcrc} "$vlcConfigDir/vlcrc"
    fi
  '';
}
