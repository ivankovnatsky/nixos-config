{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  home.file = {
    ".config/bat/config" = {
      text = ''
        --tabs="0"
      '';
    };

    ".config/git/config" = {
      text = ''
        [commit]
        	gpgSign = true

        [core]
        	editor = "nvim"
        	filemode = true

        [include]
        	path = "~/.config/git/config-home"

        [includeIf "gitdir:~/Sources/Work/"]
        	path = "~/.config/git/config-work"

        [merge]
        	tool = "vimdiff"

        [mergetool]
        	keepBackup = false
        	prompt = true

        [mergetool "vimdiff"]
        	cmd = "nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'"

        [pull]
        	rebase = false

        [push]
        	default = "current"
      '';
    };

    ".config/git/config-type.template" = {
      text = ''
        [user]
        	email = 
        	name = 
        	signingKey = 
      '';
    };

    ".zshrc" = {
      text = ''
        if [ -n "''${commands[fzf-share]}" ]; then
            source "$(fzf-share)/key-bindings.zsh"
            source "$(fzf-share)/completion.zsh"
        fi
      '';
    };

    ".gitignore" = {
      text = ''
        *
      '';
    };

    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

    ".config/mpv/config" = {
      text = ''
        alang=eng
        force-seekable=yes
        fs=yes
        hwdec=yes
        opengl-pbo=yes
        osc=no
        osd-level=0
        save-position-on-quit=yes
        slang=eng
        ytdl-format='bestvideo+bestaudio/best'
        image-display-duration=5
      '';
    };

    ".config/tmuxinator/default.yml" = {
      text = ''
        name: default
        root: ~/

        windows:
          - nvim-work: cd ~/Sources/Work && nvim
          - cli-work: cd ~/Sources/Work/
          - nvim-home: cd ~/Sources/SourceHut/ && nvim
          - cli-home: cd ~/Sources/SourceHut
      '';
    };
  };

  home.stateVersion = "21.03";
}
