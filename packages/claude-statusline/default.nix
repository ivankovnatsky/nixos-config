{
  lib,
  pkgs,
  git,
}:

pkgs.writeShellScriptBin "claude-statusline" ''
  export PATH="${lib.makeBinPath [ git ]}:$PATH"
  exec ${pkgs.python3}/bin/python ${./claude-statusline.py} "$@"
''
