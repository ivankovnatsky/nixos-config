{
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/power/sleep.nix
  # To prevent sleep, place "never".
  power.sleep = {
    computer = "never"; # default: 1
    display = 10; # default: 10
    harddisk = "never"; # default: 10
  };

  # local.services.pmset = {
  #   enable = true;
  #
  #   # To verify the current power management schedule state:
  #   # ```console
  #   # sudo pmset -g sched
  #   # ```
  #   schedules = {
  #     Sleep = {
  #       enable = true;
  #       time = "22:20:00";
  #       action = "sleep";
  #     };
  #
  #     Wake = {
  #       enable = true;
  #       time = "07:00:00";
  #       action = "wakeorpoweron";
  #     };
  #   };
  # };
}
