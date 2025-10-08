{ pkgs, ... }:

{
  imports = [
    ../../../home/btop.nix
    ../../../home/rebuild-diff.nix
  ];
}
