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
    extraGroups = [ "input" ];
    openssh.authorizedKeys.keys = [
      config.flags.sshKeys.pro
      config.flags.sshKeys.a3
    ];
  };
  programs.fish.enable = true;
}
