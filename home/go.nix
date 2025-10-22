{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  hostName = osConfig.networking.hostName;
  useAbsolutePath = hostName == "Ivans-Mac-mini";
  absoluteGoPath = "/Volumes/Storage/Data/go";
  relativeGoPath = "go";

  # Machines using home-manager release (25.05) - use old goPath format
  # Machines using home-manager unstable - use new env format
  isRelease = lib.elem hostName [ "Ivans-Mac-mini" "bee" ];
in
{
  programs.go = if isRelease then {
    # Old format for release (home-manager 25.05)
    enable = true;
    goPath = if useAbsolutePath then null else relativeGoPath;
  } else {
    # New format for unstable (home-manager with env support)
    enable = true;
    env = {
      GOPATH = if useAbsolutePath then absoluteGoPath else "$HOME/${relativeGoPath}";
      GO111MODULE = "on";
    };
  };

  home.sessionVariables = if isRelease then (
    {
      GO111MODULE = "on";
    }
    // (
      if useAbsolutePath then
        {
          GOPATH = absoluteGoPath;
        }
      else
        { }
    )
  ) else { };

  home.sessionPath = [
    (if useAbsolutePath then "${absoluteGoPath}/bin" else "$HOME/${relativeGoPath}/bin")
  ];

  home.packages = with pkgs; [
    gopls
    go-tools
    golangci-lint
    delve
  ];
}
