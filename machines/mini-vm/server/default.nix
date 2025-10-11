{
  imports = [
    ./matrix

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./media

    ../../../nixos/rebuild-diff.nix
  ];
}
