{
  pkgs,
  taskwarrior3,
  ...
}:

pkgs.writeShellScriptBin "task-mgmt" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      taskwarrior3
      pkgs.nushell
      pkgs.reminders-cli
    ]
  }:$PATH"
  exec ${pkgs.python3}/bin/python3 ${./task-mgmt.py} "$@"
''
