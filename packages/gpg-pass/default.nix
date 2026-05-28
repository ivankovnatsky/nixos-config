{ pkgs }:

pkgs.writeShellScriptBin "gpg-pass" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./gpg-pass.py} "$@"
''
