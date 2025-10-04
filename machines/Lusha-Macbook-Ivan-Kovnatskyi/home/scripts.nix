{ pkgs, ... }:
let
  scriptPath = ./scripts;

  # Define scripts that need external dependencies
  scriptsWithDeps = {
    "jira-custom.py" = {
      type = "python";
      deps = ps: [ ps.jira ];
    };
  };

  # Wrap Python script with dependencies
  wrapPythonScript =
    scriptName: config:
    let
      binaryName = pkgs.lib.removeSuffix ".py" scriptName;
    in
    pkgs.writeShellScriptBin binaryName ''
      exec ${pkgs.python3.withPackages config.deps}/bin/python ${scriptPath}/${scriptName} "$@"
    '';

  # Create packages for scripts with dependencies
  depsPackages = builtins.attrValues (
    builtins.mapAttrs (
      name: config:
      if config.type == "python" then
        wrapPythonScript name config
      else
        throw "Unknown script type: ${config.type}"
    ) scriptsWithDeps
  );
in
{
  home.packages = depsPackages;
}
