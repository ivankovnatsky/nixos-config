{
  inputs,
  pkgs,
  system,
  ...
}:
let
  steipeteTools = inputs.nix-steipete-tools.packages.${system};
in
{
  home.packages =
    (with pkgs; [
      gitleaks
      gofumpt
      golangci-lint
      macmon
      music-export
      nixpkgs-darwin-master-ytdlp.yt-dlp
      nodePackages.prettier
      ruff
      sesh
      shellcheck
      shfmt
      stylua
      treefmt
    ])
    ++ (with steipeteTools; [
      peekaboo
      sag
      summarize
    ]);
}
