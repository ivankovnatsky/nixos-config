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
    giffer
    gh-repos-sync
    macmon
    sesh
    treefmt
    typos
  ];
}
