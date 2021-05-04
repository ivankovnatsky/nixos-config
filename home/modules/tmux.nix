{ pkgs, ... }:

{

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";

    sensibleOnTop = true;

    tmuxinator.enable = true;

    plugins = with pkgs; [ tmuxPlugins.sensible tmuxPlugins.yank ];

    extraConfig = ''
      set -g status-bg colour234
      set -g status-fg colour252

      set -g window-status-current-style fg=colour255,bg=colour241

      set -g terminal-overrides ",alacritty:RGB"

      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
    '';
  };

  home.file = {

    ".config/tmuxinator/home.yml" = {
      text = ''
        name: home
        root: ~/

        windows:
          - nvim: nvim
          - cli:
      '';
    };

    ".config/tmuxinator/work.yml" = {
      text = ''
        name: work
        root: ~/Sources/Work

        windows:
          - nvim: nvim
          - cli:
      '';
    };

  };

}
