{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.jira ]);
in
pkgs.writeShellScriptBin "jira-custom" ''
  exec ${python}/bin/python ${./jira-custom.py} "$@"
''
