{ ... }:

{
  programs.git = {
    enable = true;

    extraConfig = {
      commit.gpgsign = true;

      core = {
        editor = "nvim";
        filemode = true;
      };

      include.path = "~/.config/git/config-home";
      includeIf."gitdir:~/Sources/Work/".path = "~/.config/git/config-work";

      merge.tool = "nvim";

      mergetool = {
        keepBackup = false;
        prompt = true;
      };

      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';

      pull.rebase = false;
      push.default = "current";
    };
  };

  home.file = {
    ".config/git/config-home" = {
      text = ''
        [user]
        	email = "ikovnatsky@protonmail.ch"
        	name = "Ivan Kovnatsky"
        	signingKey = "ikovnatsky@protonmail.ch"
      '';
    };

    ".config/git/config-work" = {
      text = ''
        [user]
        	email = "Ivan.Kovnatsky@tui.co.uk"
        	name = "Ivan Kovnatsky"
        	signingKey = "Ivan.Kovnatsky@tui.co.uk"
      '';
    };
  };
}
