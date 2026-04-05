{ pkgs }:

pkgs.writeShellScriptBin "forgejo-mgmt" ''
  export PATH="${pkgs.lib.makeBinPath [ pkgs.gnupg ]}:$PATH"
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.click
    ])
  }/bin/python ${./forgejo-mgmt.py} "$@"
''
