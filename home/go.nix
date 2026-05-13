{
  config,
  pkgs,
  ...
}:

{
  programs.go = {
    enable = true;
    env = {
      GOPATH = config.local.tools.goPath;
      GO111MODULE = "on";
    };
  };

  home.sessionPath = [ "${config.local.tools.goPath}/bin" ];

  home.packages = with pkgs; [
    gopls
    go-tools
    golangci-lint
    delve
  ];
}
