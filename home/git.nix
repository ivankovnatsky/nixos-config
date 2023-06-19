{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gitAndTools.pre-commit
    git-crypt
    git-remote-codecommit
    pinentry
    gitui
  ];

  # Git started to read global config and opens up osxkeychain windows first by
  # default, I've tried sung override, but that re-builds the package, that's
  # too much
  home.sessionVariables = {
    GIT_CONFIG_NOSYSTEM = "true";
  };

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
      "__worktrees/"
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
