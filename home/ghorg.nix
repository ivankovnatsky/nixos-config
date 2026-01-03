{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.ghorg ];

  # https://github.com/gabrie30/ghorg/blob/master/sample-conf.yaml
  sops.templates."ghorg-conf.yaml".content = ''
    # General Configuration
    GHORG_SCM_TYPE: github
    GHORG_CLONE_PROTOCOL: https
    GHORG_CLONE_TYPE: org
    GHORG_NO_CLEAN: true
    GHORG_FETCH_ALL: true
    GHORG_QUIET: true
    GHORG_ABSOLUTE_PATH_TO_CLONE_TO: ${config.home.homeDirectory}/Sources/github.com
    GHORG_SKIP_ARCHIVED: true # Skip archived repositories

    # GitHub Configuration
    GHORG_GITHUB_TOKEN: ${config.sops.placeholder.github-token}
  '';

  home.activation.linkGhorgConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/ghorg
    $DRY_RUN_CMD ln -sf ${config.sops.templates."ghorg-conf.yaml".path} ${config.home.homeDirectory}/.config/ghorg/conf.yaml
  '';
}
