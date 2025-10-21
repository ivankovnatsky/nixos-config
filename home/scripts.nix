{ pkgs, lib, ... }:
let
  scriptFiles = builtins.readDir ./scripts;
  scriptPath = ./scripts;

  # Define your aliases here as an attribute set
  # Format: "original-name" = [ "alias1" "alias2" ... ]
  scriptAliases = {
    "create-pr" = [ "open-pr" ];
    "eat" = [ "yank" ];
    "grep-find" = [ "rg-fzf" ];
  };

  processScript =
    scriptName:
    let
      scriptContents = builtins.readFile (scriptPath + "/${scriptName}");
      bashShebang = "#!${pkgs.bash}/bin/bash";
      scriptWithFixedShebang = builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ bashShebang ] scriptContents;
      binaryName = lib.removeSuffix ".sh" scriptName;
    in
    pkgs.writeScriptBin binaryName scriptWithFixedShebang;

  scriptNames = builtins.attrNames scriptFiles;
  scriptPackages = map processScript scriptNames;

  # Helper function to create an alias script
  createAlias =
    originalDerivation: alias:
    pkgs.writeScriptBin alias ''
      #!${pkgs.bash}/bin/bash
      exec ${originalDerivation}/bin/${originalDerivation.name} "$@"
    '';

  # Generate all aliases
  makeAliases =
    scriptName:
    let
      original = lib.removeSuffix ".sh" scriptName;
      originalDerivation = builtins.head (builtins.filter (p: p.name == original) scriptPackages);
      aliases = scriptAliases.${original} or [ ];
    in
    map (alias: createAlias originalDerivation alias) aliases;

  allAliases = lib.flatten (map makeAliases scriptNames);

  # Create an attribute set mapping script names to their derivations
  scriptDerivations = builtins.listToAttrs (
    map (script: {
      name = lib.removeSuffix ".sh" script;
      value = builtins.head (
        builtins.filter (p: p.name == lib.removeSuffix ".sh" script) scriptPackages
      );
    }) scriptNames
  );
in
{
  home.packages = scriptPackages ++ allAliases;
  # Export the script derivations for use in other modules
  _module.args.scripts = scriptDerivations;
}
