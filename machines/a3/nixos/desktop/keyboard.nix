{
  hardware.keyboard.zsa.enable = true;

  # Ergodox EZ exposes a "System Control" HID interface that udev tags as a
  # joystick (ID_INPUT_JOYSTICK=1). Sekiro/DS2 grab the first joystick they
  # enumerate and ignore the real controller, forcing a keyboard unplug to
  # play. Clear the tag -- normal keyboard input is unaffected.
  # https://steamcommunity.com/app/814380/discussions/0/592908590021573765/
  # https://www.reddit.com/r/linux_gaming/comments/1s6owdn/controller_not_working_in_sekiro_shadows_die_twice/
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTRS{idVendor}=="3297", ATTRS{idProduct}=="2030", ENV{ID_INPUT_JOYSTICK}=""
  '';
}
