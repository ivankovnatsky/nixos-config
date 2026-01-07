{ pkgs, ... }:

pkgs.writeShellScriptBin "launchd-mgmt" ''
  exec ${pkgs.python3}/bin/python ${./launchd-mgmt.py} "$@"
''
