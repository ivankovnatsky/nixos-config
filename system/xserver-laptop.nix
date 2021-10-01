{
  services = {
    xserver = {
      libinput = {
        enable = true;

        touchpad = {
          additionalOptions = ''MatchIsTouchpad "on"'';
          naturalScrolling = true;
          tapping = false;
        };
      };

      extraConfig = ''
        Section "Monitor"
          Identifier "eDP"
          Option "RightOf" "DisplayPort-1"
          Option "DPMS" "true"
        EndSection
        Section "Monitor"
          Identifier "DisplayPort-1"
          Option "PreferredMode" "3840x2160"
          Option "Position" "0 0"
          Option "LeftOf" "eDP"
          Option "DPMS" "true"
        EndSection
      '';

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
