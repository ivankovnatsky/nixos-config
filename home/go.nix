{
  pkgs,
  ...
}:

let
  relativeGoPath = "go";
in
{
  programs.go =  {
    enable = true;
    env = {
      GOPATH = "$HOME/${relativeGoPath}";
      GO111MODULE = "on";
    };
  };

  home.sessionVariables = { };

  home.sessionPath = [
    "$HOME/${relativeGoPath}/bin"
  ];

  home.packages = with pkgs; [
    gopls
    go-tools
    golangci-lint
    delve
  ];
}
