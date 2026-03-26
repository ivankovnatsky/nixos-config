{ pkgs }:

pkgs.writeShellScriptBin "forgejo-mgmt" ''
  export PATH="${pkgs.lib.makeBinPath [ pkgs.gnupg ]}:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./forgejo-mgmt.py} "$@"
''
