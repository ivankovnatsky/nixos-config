{
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/power/sleep.nix
  # To prevent sleep, place "never".
  power.sleep = {
    computer = "never"; # default: 1
    display = 10; # default: 10
    harddisk = "never"; # default: 10
  };

  local.services.pmset = {
    enable = true;

    # To verify the current power management schedule state:
    # ```console
    # sudo pmset -g sched
    # ```
    schedules = {
      ShutDown = {
        enable = true;
        time = "22:30:00";
        action = "shutdown";
      };
    };
  };
}
