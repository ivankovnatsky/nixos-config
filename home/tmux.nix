{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";

    # https://rsapkf.xyz/blog/enabling-italics-vim-tmux
    terminal = "xterm-256color";

    sensibleOnTop = false;
    tmuxp.enable = true;

    plugins = with pkgs; [ tmuxPlugins.sensible tmuxPlugins.yank ];

    extraConfig = ''
      set -g status-bg colour0
      set -g status-fg colour15

      set -g window-status-current-style fg=colour16,bg=colour15

      set -g terminal-overrides ",alacritty:RGB"

      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
    '';
  };

  home.file = {
    ".config/tmuxp/home.yml" = {
      text = ''
        session_name: home
        start_directory: ~/Sources/Home/GitHub/nixos-config/
        windows:
        - window_name: editor
          panes:
            - shell_command:
                - nvim
        - window_name: cli
          focus: true
      '';
    };

    ".config/tmuxp/work.yml" = {
      text = ''
        session_name: work
        start_directory: ~/Sources/Work/
        windows:
        - window_name: editor
          panes:
            - shell_command:
                - nvim
        - window_name: cli
          focus: true
      '';
    };
  };
}
