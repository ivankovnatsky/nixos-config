{
  lib,
  pkgs,
  reminders-cli,
  taskwarrior3,
  ...
}:

pkgs.writeShellScriptBin "taskmanager" ''
  export PATH="${
    lib.makeBinPath (
      [ taskwarrior3 ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        reminders-cli
      ]
    )
  }:$PATH"
  exec ${
    pkgs.python3.withPackages (ps: [ ps.click ])
  }/bin/python ${./taskmanager.py} "$@"
''
