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

  # `programs.go.env` only writes the `go env` file (`~/Library/Application
  # Support/go/env`); it does not export `$GOPATH` into the shell. Export it
  # explicitly so `$GOPATH` is available as an environment variable for the
  # user and tooling. (`home.sessionPath` below puts `$GOPATH/bin` on PATH.)
  home.sessionVariables.GOPATH = config.local.tools.goPath;

  home.sessionPath = [ "${config.local.tools.goPath}/bin" ];

  home.packages = with pkgs; [
    gopls
    go-tools
    golangci-lint
    delve
  ];
}
