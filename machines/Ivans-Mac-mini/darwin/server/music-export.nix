{ pkgs, ... }:

{
  system.activationScripts.musicExport.text = ''
    echo "Running Music library export..."
    ${pkgs.music-export}/bin/music-export || echo "Music export failed (Music.app may not be accessible)"
  '';
}
