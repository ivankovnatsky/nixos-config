{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user.
    linger = true;
  };
  programs.fish.enable = true;
}
