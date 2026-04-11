{ pkgs }:

pkgs.writeShellApplication {
  name = "gwq-cd";
  runtimeInputs = [
    pkgs.gwq
    pkgs.jq
  ];
  text = builtins.readFile ./gwq-cd.sh;
}
