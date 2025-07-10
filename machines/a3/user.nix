{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  programs.fish.enable = true;
}
