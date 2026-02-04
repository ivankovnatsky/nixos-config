{ config, osConfig, ... }:

{
  home.file = {
    ".config/tmuxinator/${osConfig.networking.hostName}-dev.yml" = {
      text = ''
        name: ${osConfig.networking.hostName}-dev
        startup_window: 0
        root: ${config.flags.externalStoragePath}

        windows:
          - backup:
              root: ${config.flags.externalStoragePath}/Backup
              layout: main-horizontal
              panes:
                - ls -lah
                - make sync
          - textcast:
              root: ${config.flags.externalStoragePath}/Textcast/Texts
              layout: main-horizontal
              panes:
                - nvim Texts.txt
                - |
                  cd ${config.flags.externalStoragePath}/Sources/github.com/ivankovnatsky/textcast
                  make watch-cast
          - audiobookshelf:
              root: ${config.flags.externalStoragePath}/AudioBookShelf
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
          - youtube:
              root: ${config.flags.externalStoragePath}/Youtube
              layout: main-horizontal
              panes:
                - nvim List.txt
                - make watch
      '';
    };
  };
}
