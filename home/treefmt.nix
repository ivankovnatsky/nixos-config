{ pkgs, ... }:

{
  home.packages = with pkgs; [
    treefmt
    nodePackages.prettier

    gofumpt
    golangci-lint
    nixfmt-rfc-style
    ruff
    shellcheck
    shfmt
    stylua
  ];
}
