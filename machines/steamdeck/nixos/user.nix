{
  pkgs,
  username,
  ...
}:

{
  users.users.${username} = {
    shell = pkgs.fish;
    linger = true;
  };
  programs.fish.enable = true;
}
