{
  lib,
  pkgs,
  rems,
  taskwarrior3,
  ...
}:

let
  src = ./.;
in
pkgs.writeShellScriptBin "taskmanager" ''
  export PATH="${
    lib.makeBinPath (
      [
        taskwarrior3
        pkgs.nushell
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        rems
      ]
    )
  }:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${src}/taskmanager.py "$@"
''
