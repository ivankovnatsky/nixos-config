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

    # TODO: tmux session plugin?
    plugins = with pkgs; [
      tmuxPlugins.continuum
      # FIXME: rebuild errors
      # tmuxPlugins.resurrect
      tmuxPlugins.sensible
      tmuxPlugins.yank
    ];

    # I use tabs in Terminal.app, so no need to show tmux status bar, but I
    # need tmux for 24bit color gama.
    # Yes, I just need to use another terminal, right. But I don't like them
    # for not being integrated into macOS too deep and the current
    # functionality is ok for me.
    extraConfig = ''
      # Check if running on macOS and in Terminal.app
      if-shell "[ $(uname) = 'Darwin' ] && [ $TERM_PROGRAM = 'Apple_Terminal' ]" \
        "set -g status off" \
        "set -g status on"

      set -g status-right ""
      set -g status-left-length 40

      ${
        if config.flags.darkMode then
          ''
            set -g status-bg colour0
            set -g status-fg colour15
            set -g window-status-current-style fg=colour16,bg=colour15
          ''
        else
          ''
            set -g status-bg colour15
            set -g status-fg colour0
            set -g window-status-current-style fg=colour15,bg=colour16
          ''
      }

      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      ${
        if config.flags.enableFishShell then
          ''
            set -g default-command ${pkgs.fish}/bin/fish
            set -g default-shell ${pkgs.fish}/bin/fish
          ''
        else
          ""
      }
    '';
  };


}
