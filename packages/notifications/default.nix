{ pkgs, ... }:

let
  src = ./.;
  settingsSrc = ../settings;
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "notifications" ''
  export PYTHONPATH="${settingsSrc}''${PYTHONPATH:+:$PYTHONPATH}"
  exec ${python}/bin/python ${src}/notifications.py "$@"
''
