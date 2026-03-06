{
  lib,
  pkgs,
  reminders-cli,
  taskwarrior3,
  ...
}:

pkgs.writeShellScriptBin "taskadd" ''
  export PATH="${
    lib.makeBinPath (
      [ taskwarrior3 ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        reminders-cli
      ]
    )
  }:$PATH"
  exec ${pkgs.python3}/bin/python ${./taskadd.py} "$@"
''
