{ pkgs }:

pkgs.writeShellScriptBin "giffer" ''
  export PATH="${pkgs.curl}/bin:$PATH"
  exec ${pkgs.python3}/bin/python ${./giffer.py} "$@"
''
