{ pkgs }:

pkgs.writeShellScriptBin "download-youtube" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.flask ps.watchdog ])}/bin/python3 ${./download-youtube.py} "$@"
''
