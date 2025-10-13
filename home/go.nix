{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  hostName = osConfig.networking.hostName;
  useAbsolutePath = hostName == "Ivans-Mac-mini";
  absoluteGoPath = "/Volumes/Storage/Data/go";
  relativeGoPath = "go";
in
{
  programs.go = {
    enable = true;
    env = {
      GOPATH = if useAbsolutePath then absoluteGoPath else "$HOME/${relativeGoPath}";
      GO111MODULE = "on";
    };
  };

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
