{ pkgs }:

pkgs.writeShellApplication {
  name = "ghq-cd";
  runtimeInputs = [
    pkgs.ghq
    pkgs.fzf
  ];
  text = builtins.readFile ./ghq-cd.sh;
}
