{ pkgs, ... }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
  settingsSrc = ../settingsctl;
  discordSrc = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ../discord;
  python = pkgs.python3.withPackages (ps: [
    ps.click
    ps.discord-webhook
  ]);
in
pkgs.writeShellScriptBin "notifications" ''
  export PYTHONPATH="${settingsSrc}:${discordSrc}''${PYTHONPATH:+:$PYTHONPATH}"
  exec ${python}/bin/python ${src}/notifications.py "$@"
''
