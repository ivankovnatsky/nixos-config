{
  lib,
  pkgs,
  gh,
  git,
}:

pkgs.writeShellScriptBin "gh-repos-sync" ''
  export PATH="${
    lib.makeBinPath [
      gh
      git
    ]
  }:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./gh-repos-sync.py} "$@"
''
