{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    includes = [{ path = "~/.config/git/config-home"; }];

    extraConfig = {
      commit.gpgsign = true;
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";

      core = {
        editor = "nvim";
        filemode = true;
      };

      mergetool = {
        keepBackup = false;
        prompt = true;
      };
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
