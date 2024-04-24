{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git-crypt
    pinentry
  ];

  # Git started to read global config and opens up osxkeychain windows first by
  # default, I've tried sung override, but that re-builds the package, that's
  # too much
  home.sessionVariables = {
    GIT_CONFIG_NOSYSTEM = "true";
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings = { };
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

    aliases = {
      a = "add";
      co = "checkout";
      c = "commit -v";
      ca = "commit -av";
      d = "diff";
      l = "log --oneline";
      p = "push";
      pp = "pull";
    };

    extraConfig = {
      init.defaultBranch = "main";
      mergetool."fugitive".cmd = ''nvim -f -c "Gvdiffsplit!" "$MERGED"'';
      merge.tool = "fugitive";
      pull.rebase = false;
      push.default = "current";

      http = {
        version = "HTTP/1.1";
        postBuffer = 157286400;
      };

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
        editor = "${config.variables.editor}";
        filemode = true;
      };

      mergetool = {
        keepBackup = false;
        prompt = true;
      };
    };
  };
}
