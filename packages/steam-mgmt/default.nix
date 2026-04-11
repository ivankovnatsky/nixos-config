{ lib, pkgs, steamcmd }:

pkgs.writeShellScriptBin "steam-mgmt" ''
  export PATH="${lib.makeBinPath [ steamcmd ]}:$PATH"
  exec ${pkgs.python3}/bin/python ${./steam-mgmt.py} "$@"
''
