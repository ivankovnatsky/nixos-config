{
  imports = [
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./radarr.nix
    ./sonarr.nix
    ./prowlarr.nix
    ./transmission.nix
    ./mgmt.nix
  ];
}
