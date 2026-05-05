{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
  discordSrc = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ../discord;
in
pkgs.writeShellScriptBin "logscanner" ''
  export PYTHONPATH="${discordSrc}''${PYTHONPATH:+:$PYTHONPATH}"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ps.discord-webhook ])}/bin/python ${src}/logscanner.py "$@"
''
