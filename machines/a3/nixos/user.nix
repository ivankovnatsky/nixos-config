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
      config.flags.sshKeys.air
    ];
  };
  programs.fish.enable = true;
}
