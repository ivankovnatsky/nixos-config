{ config, pkgs, lib, ... }:

let fishEnable = true;
in
{
  programs.tmux = {
    enable = true;

    clock24 = true;
    keyMode = "vi";

    # https://rsapkf.xyz/blog/enabling-italics-vim-tmux
    terminal = "xterm-256color";

    sensibleOnTop = false;
    tmuxinator.enable = true;

    plugins = with pkgs; [ tmuxPlugins.sensible tmuxPlugins.yank ];

    extraConfig = ''
      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
    '' + lib.optionalString fishEnable ''
      set -g default-command ${pkgs.fish}/bin/fish
      set -g default-shell ${pkgs.fish}/bin/fish
    '';
  };


  home.file = {
    ".config/tmuxinator/home.yml" = {
      text = ''
        name: home
        startup_window: 1
        root: ~/Sources/github.com/ivankovnatsky/nixos-config/

        windows:
          - editor: nvim
          - cli:
      '';
    };

    ".config/tmuxinator/work.yml" = {
      text = ''
        name: work
        startup_window: 1
        root: ${config.secrets.workRootDir}

        windows:
          - nvim:
              panes:
                - nvim
          - shell:
            - tmux set-window-option -t1 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t2 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t3 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t4 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t5 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t6 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t7 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t8 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t9 automatic-rename on
            - clear
      '';
    };

    ".config/tmuxinator/ax41.yml" = {
      text = ''
        name: ax41
        startup_window: 0

        windows:
          - shell:
            - tmux set-window-option -t0 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t1 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t2 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t3 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t4 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t5 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t6 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t7 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t8 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t9 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t10 automatic-rename on
            - clear
          - shell:
            - tmux set-window-option -t11 automatic-rename on
            - clear
      '';
    };
  };
}
