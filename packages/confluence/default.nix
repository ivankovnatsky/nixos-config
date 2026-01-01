{ pkgs }:

# Store Atlassian credentials in pass:
#
# ```console
# pass edit envrc/secrets
# ```
#
# Add:
#
# ```
# ATLASSIAN_EMAIL=your-email@example.com
# ATLASSIAN_SERVER=https://your-domain.atlassian.net
# ATLASSIAN_TOKEN=your-api-token
# ```
#
# Map to Confluence vars in ~/.envrc:
#
# ```
# export CONFLUENCE_SERVER="$ATLASSIAN_SERVER"
# export CONFLUENCE_EMAIL="$ATLASSIAN_EMAIL"
# export CONFLUENCE_API_TOKEN="$ATLASSIAN_TOKEN"
# ```

let
  python = pkgs.python3.withPackages (ps: [ ps.atlassian-python-api ps.markdown ]);
in
pkgs.writeShellScriptBin "confluence" ''
  exec ${python}/bin/python ${./confluence.py} "$@"
''
