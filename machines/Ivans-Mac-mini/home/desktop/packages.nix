{ pkgs, ... }:
{
  home.packages = with pkgs; [
    genpass
    go-grip
    ssh-to-age
    subs
  ];
}
