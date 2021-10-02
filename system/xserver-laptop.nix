{ config, ... }:

let
  laptopName = if config.device.name == "xps" then "eDP-1" else "eDP";
  monitorName = if config.device.name == "xps" then "DP-3" else "DisplayPort-1";

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

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
