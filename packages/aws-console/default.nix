{ pkgs }:

pkgs.writeShellScriptBin "aws-console" ''
  export PATH="${pkgs.lib.makeBinPath [ pkgs.fzf ]}:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./aws-console.py} "$@"
''
