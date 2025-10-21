{ pkgs }:

pkgs.writeShellScriptBin "vault-auth-fish" ''
  exec ${pkgs.fish}/bin/fish ${./vault-auth-fish.fish} "$@"
''
