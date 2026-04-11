{ lib, pkgs, steamcmd }:

pkgs.writeShellScriptBin "steam-mgmt" ''
  export PATH="${lib.makeBinPath [ steamcmd ]}:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./steam-mgmt.py} "$@"
''
