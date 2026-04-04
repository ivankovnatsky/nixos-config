{ pkgs }:

pkgs.writeShellApplication {
  name = "gwq-purge";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gwq
    pkgs.jq
  ];
  text = builtins.readFile ./gwq-purge.sh;
}
