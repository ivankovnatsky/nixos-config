{ config, pkgs, ... }:

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
      set -g status-right ""

      ${if config.flags.darkMode then ''
      set -g status-bg colour0
      set -g status-fg colour15
      set -g window-status-current-style fg=colour16,bg=colour15
      '' else ''
      set -g status-bg colour15
      set -g status-fg colour0
      set -g window-status-current-style fg=colour15,bg=colour16
      ''}

      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      ${if config.flags.enableFishShell then ''
      set -g default-command ${pkgs.fish}/bin/fish
      set -g default-shell ${pkgs.fish}/bin/fish
      '' else ""}
    '';
  };

  home.file = {
    ".config/tmuxinator/home.yml" = {
      text = ''
        name: home
        startup_window: 1
        root: ~/Sources/github.com/ivankovnatsky/nixos-config/

        windows:
          - editor: ${config.flags.editor}
          - cli:
      '';
    };

    ".config/tmuxinator/work.yml" = {
      text = ''
        name: work
        startup_window: 1
        root: ~/Sources

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
  };
}
