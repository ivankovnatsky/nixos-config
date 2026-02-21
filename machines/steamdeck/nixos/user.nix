{
  pkgs,
  username,
  ...
}:

{
  users.users.${username} = {
    shell = pkgs.fish;
    linger = true;
    extraGroups = [ "input" ];
  };
  programs.fish.enable = true;
}
