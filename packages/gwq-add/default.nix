{ pkgs }:

pkgs.writeShellApplication {
  name = "gwq-add";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gwq
  ];
  text = builtins.readFile ./gwq-add.sh;
}
