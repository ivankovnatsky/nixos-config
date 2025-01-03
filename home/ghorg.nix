{ config, ... }:

{
  home.file.".config/ghorg/conf.yaml".text = ''
    # General Configuration
    GHORG_SCM_TYPE: github
    GHORG_CLONE_PROTOCOL: https
    GHORG_CLONE_TYPE: org
    GHORG_NO_CLEAN: true
    GHORG_FETCH_ALL: true
    GHORG_QUIET: true
    GHORG_ABSOLUTE_PATH_TO_CLONE_TO: ~/Sources/github.com
    
    # GitHub Configuration
    GHORG_GITHUB_TOKEN: ${config.secrets.githubToken}
  '';
}
