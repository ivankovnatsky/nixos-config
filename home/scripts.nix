# Export script derivations as _module.args for home-manager modules
# Required by: home/nixvim/commands (uses scripts.pr)
{ pkgs, lib, ... }:
let
  scriptFiles = builtins.readDir ../scripts;
  scriptPath = ../scripts;

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

  # Create an attribute set mapping script names to their derivations
  scriptDerivations = builtins.listToAttrs (
    map
      (script: {
        name = lib.removeSuffix ".sh" script;
        value = builtins.head (
          builtins.filter (p: p.name == lib.removeSuffix ".sh" script) scriptPackages
        );
      })
      scriptNames
  );
in
{
  # Export the script derivations for use in other home-manager modules
  _module.args.scripts = scriptDerivations;
}
