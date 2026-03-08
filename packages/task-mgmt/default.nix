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
      pkgs.ripgrep
    ]
  }:$PATH"
  exec ${pkgs.bash}/bin/bash ${./task-mgmt.sh} "$@"
''
