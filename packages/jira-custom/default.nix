{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [
    ps.jira
    ps.click
    ps.rich
  ]);
in
pkgs.writeShellScriptBin "jira-custom" ''
  export PYTHONPATH="${./.}:$PYTHONPATH"
  exec ${python}/bin/python -m jira_custom "$@"
''
