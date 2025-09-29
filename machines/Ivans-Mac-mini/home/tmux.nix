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
          - articast:
              root: /Volumes/Storage/Data/Textcast/Texts
              layout: main-horizontal
              panes:
                - nvim Texts.txt
                - |
                  cd /Volumes/Storage/Data/Sources/github.com/ivankovnatsky/textcast
                  make watch-cast
          - audiobookshelf:
              root: /Volumes/Storage/Data/AudioBookShelf
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
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
