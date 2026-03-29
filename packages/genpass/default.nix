{ pkgs, genpass }:

pkgs.writeShellScriptBin "genpass" (
  builtins.replaceStrings
    [ "@genpass@" ]
    [ "${genpass}/bin/genpass" ]
    (builtins.readFile ./genpass.sh)
)
