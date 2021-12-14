{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  homeCredentialHelper = if isDarwin then "osxkeychain" else "${pkgs.rbw}/bin/git-credential-rbw";
in
{
  home.packages = with pkgs; [
    gitAndTools.pre-commit
    git-crypt
    lastpass-cli
    pinentry
    (rbw.override { withFzf = true; })
  ];

  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/git/config-home-bw";
        condition = "gitdir:~/Sources/Home/";
      }

      {
        path = "~/.config/git/config-home-bw";
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
    ".config/git/config-home-bw" = {
      text = ''
        [credential]
          helper = ${homeCredentialHelper}
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
