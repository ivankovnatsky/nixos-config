{
  config,
  pkgs,
  username,
  ...
}:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user.
    linger = true;
    openssh.authorizedKeys.keys = [
      config.flags.sshKeys.air
    ];
  };
  programs.fish.enable = true;
}
