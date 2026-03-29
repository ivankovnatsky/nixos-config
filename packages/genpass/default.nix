{ pkgs }:

let
  genpass-unwrapped = pkgs.genpass;
in
pkgs.writeShellScriptBin "genpass" (
  builtins.replaceStrings
    [ "@genpass@" ]
    [ "${genpass-unwrapped}/bin/genpass" ]
    (builtins.readFile ./genpass.sh)
)
