{
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/power/sleep.nix
  # To prevent sleep, place "never".
  power.sleep = {
    computer = 1; # default: 1
    display = 10; # default: 10
    harddisk = 10; # default: 10
  };
}
