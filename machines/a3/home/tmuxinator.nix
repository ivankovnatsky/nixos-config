{ config, ... }:

let
  homePath = config.home.homeDirectory;
in
{
  home.file = {
    ".config/tmuxinator/temperatures.yml" = {
      text = ''
        name: a3-monitoring
        startup_window: 0
        root: ${homePath}

        windows:
          - monitoring:
              layout: even-horizontal
              panes:
                - temperature
                - top
      '';
    };
  };
}
