{ pkgs }:

pkgs.writeShellScriptBin "k-number-of-replicas" ''
  exec ${pkgs.nushell}/bin/nu ${./k-number-of-replicas.nu} "$@"
''
