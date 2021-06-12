{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

in
{
  programs.git = {
    enable = true;

    includes = [{ path = "~/.config/git/config-home"; }
      {
        path = "~/.config/git/config-work";
        condition = "gitdir:~/Sources/Work/";
      }];

    extraConfig = {
      commit.gpgsign = true;
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

      credential.helper = if isDarwin then "osxkeychain" else "${
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

    ".config/git/config-work" = {
      text = ''
        [user]
          email = "ikovnatsky@bigid.com"
          name = "Ivan Kovnatsky"
          signingKey = "ikovnatsky@bigid.com"
      '';
    };
  };
}
