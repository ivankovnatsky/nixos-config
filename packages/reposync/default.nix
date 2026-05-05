{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
in
pkgs.writeShellScriptBin "reposync" ''
  export PATH="${pkgs.git}/bin:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${src}/reposync.py "$@"
''
