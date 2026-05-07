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
      gh-repos-sync
      macmon
      music-export
      sesh
      treefmt
    ])
    ++ (with steipeteTools; [
      peekaboo
      sag
      summarize
    ]);
}
