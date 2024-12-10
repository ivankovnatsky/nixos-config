{ pkgs, lib, ... }:
let
  scriptFiles = builtins.readDir ./scripts;
  scriptPath = ./scripts;
  
  processScript = scriptName:
    let
      scriptContents = builtins.readFile (scriptPath + "/${scriptName}");
      isFishScript = lib.hasSuffix ".fish" scriptName;
      isPythonScript = lib.hasSuffix ".py" scriptName;
      isGoScript = lib.hasSuffix ".go" scriptName;
      
      fishShebang = "#!${pkgs.fish}/bin/fish";
      bashShebang = "#!${pkgs.bash}/bin/bash";
      pythonShebang = "#!${pkgs.python3}/bin/python3";

      # For Go files, we'll compile them instead of handling shebangs
      processGoScript = name:
        pkgs.stdenv.mkDerivation {
          name = lib.removeSuffix ".go" name;
          src = scriptPath + "/${name}";
          buildInputs = [ pkgs.go ];
          
          # Skip unpack phase since we're dealing with a single file
          dontUnpack = true;
          
          buildPhase = ''
            # Set GOCACHE to a writable location in build directory
            export GOCACHE=$TMPDIR/go-cache
            mkdir -p $out/bin
            cp $src ${lib.removeSuffix ".go" name}.go
            go build -o $out/bin/${lib.removeSuffix ".go" name} ${lib.removeSuffix ".go" name}.go
          '';
          
          installPhase = "true";
        };

      scriptWithFixedShebang =
        if isGoScript then
          processGoScript scriptName
        else if isFishScript then
          builtins.replaceStrings [ "#!/usr/bin/env fish" ] [ fishShebang ] scriptContents
        else if isPythonScript then
          builtins.replaceStrings [ "#!/usr/bin/env python3" ] [ pythonShebang ] scriptContents
        else
          builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ bashShebang ] scriptContents;

      # Remove extension for the final binary name
      binaryName = lib.removeSuffix
        (if isFishScript then ".fish"
        else if isPythonScript then ".py"
        else if isGoScript then ".go"
        else ".sh")
        scriptName;
    in
    if isGoScript then
      scriptWithFixedShebang
    else
      pkgs.writeScriptBin binaryName scriptWithFixedShebang;

  scriptNames = builtins.attrNames scriptFiles;
  scriptPackages = map processScript scriptNames;
in
{
  home.packages = scriptPackages;
}
