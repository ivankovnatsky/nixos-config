{ lib, pkgs, ... }:
let
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;

  processScript = scriptName:
    let
      scriptPath = "${scriptsDir}/${scriptName}";
      scriptContents = builtins.readFile scriptPath;
      isFishScript = lib.hasSuffix ".fish" scriptName;
      bashShebang = "#!${pkgs.bash}/bin/bash";
      fishShebang = "#!${pkgs.fish}/bin/fish";
      scriptWithFixedShebang =
        if isFishScript
        then builtins.replaceStrings [ "#!/usr/bin/env fish" ] [ fishShebang ] scriptContents
        else builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ bashShebang ] scriptContents;
    in
    pkgs.writeScriptBin (lib.removeSuffix (if isFishScript then ".fish" else ".sh") scriptName) scriptWithFixedShebang;

  filteredScriptNames = lib.filter (scriptName: lib.hasSuffix ".sh" scriptName || lib.hasSuffix ".fish" scriptName) (builtins.attrNames scriptFiles);
  scriptPackages = builtins.map processScript filteredScriptNames;
in
{
  home.packages = scriptPackages;
}
