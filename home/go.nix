{ config, osConfig, pkgs, ... }:

let
  hostName = osConfig.networking.hostName;
  # home-manager prepends $HOME to goPath, so we need special handling for absolute paths
  useAbsolutePath = hostName == "Ivans-Mac-mini";
  absoluteGoPath = "/Volumes/Storage/Data/go";
  relativeGoPath = "go";
in
{
  programs.go = {
    enable = true;
    # For mini, we'll override the GOPATH manually since home-manager assumes relative paths
    goPath = if useAbsolutePath then null else relativeGoPath;
  };

  home.sessionVariables = {
    GO111MODULE = "on";
  } // (if useAbsolutePath then {
    GOPATH = absoluteGoPath;
  } else {});

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
