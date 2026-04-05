{ pkgs }:

pkgs.writeShellApplication {
  name = "gwq-merge";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
    pkgs.gwq
    pkgs.jq
  ];
  text = builtins.readFile ./gwq-merge.sh;
}
