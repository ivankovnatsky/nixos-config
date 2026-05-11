{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (osConfig.networking) hostName;
  useAbsolutePath = hostName == "Ivans-Mac-mini";
  absoluteGoPath = "${config.flags.externalStoragePath}/go";
  homeGoPath = "${config.home.homeDirectory}/go";
in
{
  programs.go = {
    enable = true;
    env = {
      GOPATH = if useAbsolutePath then absoluteGoPath else homeGoPath;
      GO111MODULE = "on";
    };
  };

  home.sessionPath = [
    (if useAbsolutePath then "${absoluteGoPath}/bin" else "${homeGoPath}/bin")
  ];

  home.packages = with pkgs; [
    gopls
    go-tools
    golangci-lint
    delve
  ];
}
