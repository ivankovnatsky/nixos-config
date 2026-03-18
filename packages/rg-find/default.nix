{ pkgs }:

pkgs.writeShellScriptBin "rg-find" ''
  echo "Searching files.."
  ${pkgs.ripgrep}/bin/rg --files | ${pkgs.ripgrep}/bin/rg "$@"
  echo ""
  echo "--"
  echo ""
  echo "Searching in files.."
  ${pkgs.ripgrep}/bin/rg "$@"
''
