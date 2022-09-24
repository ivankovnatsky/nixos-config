{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

in
{
  home.packages = with pkgs; [
    gitAndTools.pre-commit
    git-crypt
    pinentry
    tig
  ];

  programs.gh = {
    enable = true;

    settings = { };

    enableGitCredentialHelper = false;
  };

  programs.git = {
    enable = true;

    userEmail = "75213+ivankovnatsky@users.noreply.github.com";
    userName = "Ivan Kovnatsky";

    signing = {
      signByDefault = true;
      key = "75213+ivankovnatsky@users.noreply.github.com";
    };

    ignores = [
      ".stignore"
    ];

    extraConfig = {
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

      credential = {
        helper = "${pkgs.rbw}/bin/git-credential-rbw";
      };

      ghq = {
        root = "~/Sources";
      };

      tag = {
        forceSignAnnotated = "true";
      };

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
}
