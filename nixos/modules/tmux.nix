{ lib, pkgs, ... }:

let plugins = with pkgs; [ tmuxPlugins.sensible tmuxPlugins.yank ];

in {
  environment.systemPackages = plugins;

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    newSession = true;

    extraConfig = ''
      set -g status-bg colour234
      set -g status-fg colour252

      set -g window-status-current-style fg=colour255,bg=colour241

      set -g terminal-overrides ",alacritty:RGB"

      # https://neovim.io/doc/user/term.html#tui-cursor-shape
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

      # Load plugins
      ${lib.concatStrings (map (x: ''
        run-shell ${x.rtp}
      '') plugins)}
    '';
  };
}
