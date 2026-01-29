{ pkgs, ... }:

{
  home.packages = with pkgs; [
    treefmt
    nodePackages.prettier

    deadnix
    gofumpt
    golangci-lint
    nixfmt-rfc-style
    statix
    ruff
    shellcheck
    shfmt
    stylua
  ];
}
