{ pkgs }:

pkgs.writeShellScriptBin "reposync" ''
  export PATH="${pkgs.git}/bin:$PATH"
  exec ${pkgs.python3}/bin/python ${./reposync.py} "$@"
''
