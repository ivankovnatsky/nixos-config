{ config, osConfig, ... }:

{
  home.file = {
    ".config/tmuxinator/${osConfig.networking.hostName}-dev.yml" = {
      text = ''
        name: ${osConfig.networking.hostName}-dev
        startup_window: 0
        root: ${config.flags.miniStoragePath}

        windows:
          - crypt:
              root: ${config.flags.miniStoragePath}/Drive/Crypt
              layout: main-horizontal
              panes:
                - ls -lah
                - make sync
          - textcast:
              root: ${config.flags.miniStoragePath}/Textcast/Texts
              layout: main-horizontal
              panes:
                - nvim Texts.txt
                - |
                  cd ${config.flags.miniStoragePath}/Sources/github.com/ivankovnatsky/textcast
                  make watch-cast
          - audiobookshelf:
              root: ${config.flags.miniStoragePath}/AudioBookShelf
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
          - youtube:
              root: ${config.flags.miniStoragePath}/Youtube
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
      '';
    };
  };
}
