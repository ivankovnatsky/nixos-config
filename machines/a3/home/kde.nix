{ config, lib, pkgs, ... }:

# Set scaling manually to 200% for now.

{
  # Display scaling configuration (200%)
  # xdg.configFile."kscreenrc".text = ''
  #   [DisplaySize]
  #   Scale=2
  # '';

  # # Mouse settings - disable acceleration
  # xdg.configFile."kcminputrc".text = ''
  #   [Mouse]
  #   XLbInptAccelProfileFlat=true
  #   XLbInptPointerAcceleration=0
  # '';
}
