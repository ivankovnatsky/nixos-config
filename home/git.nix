{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  git-credentials-rbw = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/mikeboiko/58ab730afd65bca0a125bc12b6f4670d/raw/378a35d30d282c65d4d514a5acc917d30181fa5e/git-credential-rbw";
    sha256 = "sha256-/MVXA+3LHaKRUiHBDA15fN7Ndo7MXdyeIhtMTh46NxA=";
    executable = true;
  };
in
{
  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/config-home-rbw";
        condition = "gitdir:~/Sources/Home/";
      }

      {
        path = "~/.config/git/config-home-rbw";
        condition = "gitdir:~/Sources/Public/";
      }

      {
        path = "~/.config/git/config-work";
        condition = "gitdir:~/Sources/Work/";
      }
    ];

    userEmail = "75213+ivankovnatsky@users.noreply.github.com";
    userName = "Ivan Kovnatsky";
    signing = {
      signByDefault = true;
      key = "75213+ivankovnatsky@users.noreply.github.com";
    };

    extraConfig = {
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
    ".config/git/config-home-rbw" = {
      text = ''
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
