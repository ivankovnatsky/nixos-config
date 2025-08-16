{ config, osConfig, ... }:

let
  homePath = config.home.homeDirectory;
  workingPath = if osConfig.networking.hostName == "Ivans-Mac-mini" then
  "/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config"
else if osConfig.networking.hostName == "bee" then
  "/storage/Data/Sources/github.com/ivankovnatsky/nixos-config"
else
  "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
in
{
  home.file = {
    ".config/tmuxinator/nixos-config.yml" = {
      text = ''
        name: nixos-config
        startup_window: 0
        root: ${workingPath}

        windows:
          - nixos-config:
              layout: main-vertical
              panes:
                - nvim
          - shell:
              layout: main-vertical
              panes:
                - ls -lah
          - claude:
              layout: main-vertical
              panes:
                - claude
      '';
    };
  };
}
