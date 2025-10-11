{
  imports = [
    ./matrix

    # Home Automation
    ./home-automation

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./media

    ../../../nixos/rebuild-diff.nix
  ];
}
