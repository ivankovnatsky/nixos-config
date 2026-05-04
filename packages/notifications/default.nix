{ pkgs, ... }:

let
  src = ./.;
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "notifications" ''
  export PATH="${pkgs.settings}/bin:$PATH"
  exec ${python}/bin/python ${src}/notifications.py "$@"
''
