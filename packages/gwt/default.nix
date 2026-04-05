{ pkgs }:

pkgs.writeShellApplication {
  name = "gwt";
  runtimeInputs = [
    pkgs.ghq
    pkgs.fzf
    pkgs.gnugrep
    pkgs.gwq-add
  ];
  text = builtins.readFile ./gwt.sh;
}
