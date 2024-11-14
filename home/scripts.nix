{ lib, pkgs, ... }:
let
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;

  processScript = scriptName:
    let
      scriptPath = "${scriptsDir}/${scriptName}";
      scriptContents = builtins.readFile scriptPath;
      isFishScript = lib.hasSuffix ".fish" scriptName;
      isPythonScript = lib.hasSuffix ".py" scriptName;
      bashShebang = "#!${pkgs.bash}/bin/bash";
      fishShebang = "#!${pkgs.fish}/bin/fish";
      pythonShebang = "#!${pkgs.python3}/bin/python3";
      
      scriptWithFixedShebang =
        if isFishScript then
          builtins.replaceStrings [ "#!/usr/bin/env fish" ] [ fishShebang ] scriptContents
        else if isPythonScript then
          builtins.replaceStrings [ "#!/usr/bin/env python3" ] [ pythonShebang ] scriptContents
        else
          builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ bashShebang ] scriptContents;
          
      # Remove extension for the final binary name
      binaryName = lib.removeSuffix 
        (if isFishScript then ".fish"
         else if isPythonScript then ".py"
         else ".sh") 
        scriptName;
    in
    pkgs.writeScriptBin binaryName scriptWithFixedShebang;

  # Add .py to filtered extensions
  filteredScriptNames = lib.filter 
    (scriptName: lib.hasSuffix ".sh" scriptName || 
                lib.hasSuffix ".fish" scriptName || 
                lib.hasSuffix ".py" scriptName) 
    (builtins.attrNames scriptFiles);
    
  scriptPackages = builtins.map processScript filteredScriptNames;
in
{
  home.packages = scriptPackages;
}
