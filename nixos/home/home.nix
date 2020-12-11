{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  programs = {
    git = {
      enable = true;

      extraConfig = {
        commit = { gpgSign = true; };
        push = { default = "current"; };
        pull = { rebase = false; };
        core = {
          filemode = true;
          editor = "nvim";
        };
        merge = { tool = "vimdiff"; };
        mergetool = {
          prompt = true;
          keepBackup = false;
        };
        mergetool."vimdiff".cmd =
          "nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
        include.path = "~/.config/git/config-home";
        includeIf."gitdir:~/Sources/Work/".path = "~/.config/git/config-work";
      };
    };
  };

  home.file = {
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
  };

  home.stateVersion = "21.03";
}
