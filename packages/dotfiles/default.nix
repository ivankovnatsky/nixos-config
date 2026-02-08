{ pkgs }:

pkgs.writeShellScriptBin "dotfiles" ''
  export PATH="${pkgs.git}/bin:$PATH"
  exec ${pkgs.python3}/bin/python ${./dotfiles.py} "$@"
''
