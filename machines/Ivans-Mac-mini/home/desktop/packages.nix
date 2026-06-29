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
    macmon
    treefmt
    typos
    nixpkgs-nixos-master-edge.antigravity-cli
  ];
}
