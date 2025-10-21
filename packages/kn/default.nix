{ pkgs }:

pkgs.writeShellScriptBin "kn" ''
  exec ${pkgs.nushell}/bin/nu ${./kn.nu} "$@"
''
