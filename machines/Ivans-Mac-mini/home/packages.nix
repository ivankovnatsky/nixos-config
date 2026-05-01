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
      (python313.withPackages (
        ps: with ps; [
          grip
          # markitdown
        ]
      ))
      macmon
      music-export
      nixpkgs-darwin-master-ytdlp.yt-dlp
      sesh
      treefmt
    ])
    ++ (with steipeteTools; [
      peekaboo
      sag
      summarize
    ]);
}
