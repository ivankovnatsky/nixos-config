{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  git-credentials-rbw = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/ivankovnatsky/a4074eb9202f7067fc9a19faa4b399d2/raw/b8bbbcafd67648dc3fb67f482f8ad91a1989d4c5/git-credentials-rbw";
    sha256 = "sha256-h7h369YuX0pEmmAEHbWzlKKQjo6oVL0vsxmRxy1p8F8=";
    executable = true;
  };
in
{
  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/config-home";
        condition = "gitdir:~/Sources/Home/";
      }

      {
        path = "~/.config/git/config-work";
        condition = "gitdir:~/Sources/Work/";
      }
    ];

    extraConfig = {
      commit.gpgsign = true;
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

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
          [credential]
            helper = "${git-credentials-rbw}";
      '';
    };

    ".config/git/config-work" = {
      text = ''
        [user]
          email = "ikovnatsky@bigid.com"
          name = "Ivan Kovnatsky"
          signingKey = "ikovnatsky@bigid.com"
          [credential]
            helper = "lastpass";
      '';
    };
  };
}
