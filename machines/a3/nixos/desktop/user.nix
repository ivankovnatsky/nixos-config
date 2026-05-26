{
  config,
  pkgs,
  username,
  ...
}:

{
  users.users.${username} = {
    shell = pkgs.fish;
    linger = true;
    openssh.authorizedKeys.keys = [
      config.inventory.sshKeys.air
      config.inventory.sshKeys.mini
    ];
  };
  programs.fish.enable = true;
}
