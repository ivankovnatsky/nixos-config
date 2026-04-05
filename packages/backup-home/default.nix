{
  lib,
  pkgs,
  pigz,
  curl,
  openssh,
  rclone,
}:

pkgs.writeShellScriptBin "backup-home" ''
  export PATH="${
    lib.makeBinPath [
      pigz
      curl
      openssh
      rclone
    ]
  }:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./backup-home.py} "$@"
''
