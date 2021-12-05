{ config, ... }:

let
  laptopName = "eDP";
  monitorName = "DisplayPort-1";

in
{
  services = {
    xserver = {
      libinput = {
        enable = true;

        touchpad = {
          additionalOptions = ''MatchIsTouchpad "on"'';
          disableWhileTyping = true;
          naturalScrolling = true;
          tapping = false;
        };
      };

      extraConfig = ''
        Section "Monitor"
          Identifier "${laptopName}"
          Option "RightOf" "${monitorName}"
          Option "Position" "3840 960"
          Option "DPMS" "true"
        EndSection
        Section "Monitor"
          Identifier "${monitorName}"
          Option "PreferredMode" "3840x2160"
          Option "Position" "0 0"
          Option "LeftOf" "${laptopName}"
          Option "DPMS" "true"
        EndSection
      '';
    };
  };
}
