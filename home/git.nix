{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    extraConfig = {
      commit.gpgsign = true;
      init.defaultBranch = "main";
      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";

      core = {
        editor = "nvim";
        filemode = true;
      };

      include.path = "~/.config/git/config-home";

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
          email = "75213+ivankovnatsky@users.noreply.github.com"
          name = "Ivan Kovnatsky"
          signingKey = "75213+ivankovnatsky@users.noreply.github.com"
      '';
    };
  };
}
