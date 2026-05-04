{ pkgs }:

pkgs.writeShellApplication {
  name = "gwq-add";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gwq
  ];
  text = ''
    export WORD_FILE="''${WORD_FILE:-${pkgs.scowl}/share/dict/wamerican.50}"
  ''
  + builtins.readFile ./gwq-add.sh;
}
