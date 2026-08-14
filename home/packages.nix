{ pkgs, ... }:

{
  home.packages = with pkgs; [
    antigravity-cli
    age
    aria2
    pre-commit
    rumdl
    delta
    dust
    ffmpeg
    genpass
    ggh
    gitleaks
    gofumpt
    golangci-lint
    go-grip
    hyperfine
    jq
    prettier
    nodejs
    pigz
    poppler-utils
    ruff
    shellcheck
    shfmt
    sops
    ssh-to-age
    stylua
    tree
    wget
    zoxide
    uv
  ];
}
