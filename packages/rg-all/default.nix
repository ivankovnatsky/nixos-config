{ pkgs }:

pkgs.writeShellScriptBin "rg-all" ''
  clear
  exec ${pkgs.ripgrep}/bin/rg \
    --no-ignore \
    --no-ignore-dot \
    --no-ignore-exclude \
    --no-ignore-files \
    --no-ignore-global \
    --no-ignore-parent \
    --no-ignore-vcs \
    --hidden \
    "$@"
''
