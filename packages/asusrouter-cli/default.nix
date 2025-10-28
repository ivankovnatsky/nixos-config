{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "asusrouter-cli" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.asusrouter ])}/bin/python ${./asusrouter-cli.py} "$@"
''
