{
  services = {
    xserver = {
      libinput = {
        enable = true;

        touchpad = {
          additionalOptions = ''MatchIsTouchpad "on"'';
          middleEmulation = true;
          tappingDragLock = true;
          disableWhileTyping = true;
          naturalScrolling = true;
          tapping = true;
        };
      };
    };
  };
}
