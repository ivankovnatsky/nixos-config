{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  homeDir = if isDarwin then "/Users" else "/home";
in
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/taskwarrior.nix
  programs.taskwarrior = {
    enable = true;
    dataLocation = "${homeDir}/ivan/.task/";
    colorTheme = if config.flags.darkMode then "no-color" else "light-256";
  };
}
