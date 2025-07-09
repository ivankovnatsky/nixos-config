{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    clock24 = true;
    keyMode = "vi";
    terminal = "xterm-256color";

    plugins = with pkgs.tmuxPlugins; [
      continuum
      sensible
      yank
    ];

    extraConfig = ''
      set -g status-right ""
      set -g status-left-length 40

      # Dark theme for server environment
      set -g status-bg colour0
      set -g status-fg colour15
      set -g window-status-current-style fg=colour16,bg=colour15

      # Cursor shape support for neovim
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

      # Use fish shell as default
      set -g default-command ${pkgs.fish}/bin/fish
      set -g default-shell ${pkgs.fish}/bin/fish
    '';
  };

  environment.systemPackages = with pkgs; [
    tmux
  ];
}
