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
      isFishScript = lib.hasSuffix ".fish" scriptName;
      isPythonScript = lib.hasSuffix ".py" scriptName;
      isGoScript = lib.hasSuffix ".go" scriptName;
      isNuScript = lib.hasSuffix ".nu" scriptName;

      fishShebang = "#!${pkgs.fish}/bin/fish";
      bashShebang = "#!${pkgs.bash}/bin/bash";
      pythonShebang = "#!${pkgs.python3}/bin/python3";
      nuShebang = "#!${pkgs.nushell}/bin/nu";

      # For Go files, we'll compile them instead of handling shebangs
      processGoScript =
        name:
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
        else if isNuScript then
          builtins.replaceStrings [ "#!/usr/bin/env nu" ] [ nuShebang ] scriptContents
        else
          builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ bashShebang ] scriptContents;

      # Remove extension for the final binary name
      binaryName = lib.removeSuffix (
        if isFishScript then
          ".fish"
        else if isPythonScript then
          ".py"
        else if isGoScript then
          ".go"
        else if isNuScript then
          ".nu"
        else
          ".sh"
      ) scriptName;
    in
    if isGoScript then
      scriptWithFixedShebang
    else
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
      original = lib.removeSuffix ".sh" (
        lib.removeSuffix ".fish" (lib.removeSuffix ".py" (lib.removeSuffix ".go" scriptName))
      );
      originalDerivation = builtins.head (builtins.filter (p: p.name == original) scriptPackages);
      aliases = scriptAliases.${original} or [ ];
    in
    map (alias: createAlias originalDerivation alias) aliases;

  # Generate all alias packages
  # allAliases = lib.flatten (
  #   map (name: makeAliases (lib.removeSuffix ".sh" (lib.removeSuffix ".fish" (lib.removeSuffix ".py" (lib.removeSuffix ".go" name)))))
  #     scriptNames
  # );

  # Generate all alias packages
  allAliases = lib.flatten (map makeAliases scriptNames);

  # Create an attribute set mapping script names to their derivations
  scriptDerivations = builtins.listToAttrs (
    map (script: {
      name = lib.removeSuffix ".sh" (
        lib.removeSuffix ".fish" (
          lib.removeSuffix ".py" (lib.removeSuffix ".go" (lib.removeSuffix ".nu" script))
        )
      );
      value = builtins.head (
        builtins.filter (
          p:
          p.name == lib.removeSuffix ".sh" (
            lib.removeSuffix ".fish" (
              lib.removeSuffix ".py" (lib.removeSuffix ".go" (lib.removeSuffix ".nu" script))
            )
          )
        ) scriptPackages
      );
    }) scriptNames
  );
in
{
  home.packages = scriptPackages ++ allAliases;
  # Export the script derivations for use in other modules
  _module.args.scripts = scriptDerivations;
}
