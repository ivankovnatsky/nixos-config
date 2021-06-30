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
    tmuxinator.enable = true;

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
    ".config/tmuxinator/home.yml" = {
      text = ''
        name: home
        startup_window: 2
        root: ~/Sources/Home/GitHub/nixos-config/

        windows:
          - editor: nvim
          - cli:
      '';
    };

    ".config/tmuxinator/work.yml" = {
      text = ''
        name: work
        startup_window: 2
        root: ~/Sources/Work

        windows:
          - editor: nvim
          - cli:
      '';
    };
  };
}
