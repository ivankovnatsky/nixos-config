{ pkgs }:

pkgs.writeShellScriptBin "vault-auth" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./vault-auth.py} "$@"
''
