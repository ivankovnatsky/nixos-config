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
    ];
  };
  programs.fish.enable = true;
}
