{ config, ... }:

{
  home.file = {
    ".config/tmuxinator/Ivans-Mac-mini-dev.yml" = {
      text = ''
        name: Ivans-Mac-mini-dev
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
              root: /Volumes/Storage/Data/Articast/Articles
              layout: main-horizontal
              panes:
                - vim Articles.txt
                - |
                  cd /Volumes/Storage/Data/Sources/github.com/ivankovnatsky/articast
                  make watch-cast
          - audiobookshelf:
              root: /Volumes/Storage/Data/AudioBookShelf
              layout: main-horizontal
              panes:
                - vim List.txt
                - make watch
      '';
    };
  };
}
