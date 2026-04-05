{ pkgs }:

pkgs.writeShellApplication {
  name = "grwt";
  runtimeInputs = [
    pkgs.ghq
    pkgs.fzf
    pkgs.gnugrep
    pkgs.gwq-add
  ];
  text = builtins.readFile ./grwt.sh;
}
