{ osConfig, ... }:

{
  home.file = {
    ".config/tmuxinator/${osConfig.networking.hostName}-dev.yml" = {
      text = ''
        name: ${osConfig.networking.hostName}-dev
        startup_window: 0
        root: /Volumes/Storage/Data

        windows:
          - crypt:
              root: /Volumes/Storage/Data/Drive/Crypt
              layout: main-horizontal
              panes:
                - ls -lah
                - make sync
          - youtube:
              root: /Volumes/Storage/Data/Youtube
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
      '';
    };
  };
}
