{ pkgs, ... }:

{
  home.packages = with pkgs; [
    treefmt
    prettier

    nix-find-orphans
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
