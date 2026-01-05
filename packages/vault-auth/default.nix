{ pkgs }:

pkgs.writeShellScriptBin "vault-auth" ''
  exec ${pkgs.python3}/bin/python ${./vault-auth.py} "$@"
''
