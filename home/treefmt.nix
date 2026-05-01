{ pkgs, ... }:

{
  home.packages = with pkgs; [
    treefmt
    prettier

    deadnix
    gofumpt
    golangci-lint
    nixfmt
    statix
    ruff
    shellcheck
    shfmt
    stylua
  ];
}
