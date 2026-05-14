{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
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
    typos
  ];
}
