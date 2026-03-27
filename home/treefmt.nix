{ pkgs, ... }:

{
  home.packages = with pkgs; [
    treefmt
    nodePackages.prettier

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
