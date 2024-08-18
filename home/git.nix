{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ghq
    git-crypt
  ];

  # Git started to read global config and opens up osxkeychain windows first by
  # default, I've tried using override, but that re-builds the package, that's
  # too much
  home.sessionVariables = {
    GIT_CONFIG_NOSYSTEM = "true";
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
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
    includes = [
      {
        condition = "gitdir:~/Sources/github.com/dealroadshow/";
        contents.user = {
          email = config.secrets.workEmail;
          signingKey = config.secrets.workEmail;
        };
      }
    ];
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
      mergetool =
        let
          vimCommand = "vim -f -d -c 'wincmd J' \"$LOCAL\" \"$BASE\" \"$REMOTE\" \"$MERGED\"";
          neovimCommand = ''nvim -f -c "Gvdiffsplit!" "$MERGED"'';
          mergetoolOptions = {
            keepBackup = false;
            prompt = true;
          };
        in
        if config.flags.editor == "nvim"
        then {
          "fugitive".cmd = neovimCommand;
          tool = "fugitive";
        } // mergetoolOptions
        else {
          cmd = vimCommand;
        } // mergetoolOptions;
      merge.tool = if config.flags.editor == "nvim" then "fugitive" else "vimdiff";
      pull.rebase = false;
      push.default = "current";
      http = {
        version = "HTTP/1.1";
        postBuffer = 157286400;
      };
      ghq = {
        root = "~/Sources";
      };
      tag = {
        forceSignAnnotated = "true";
      };
      core = {
        editor = "${config.flags.editor}";
        filemode = true;
      };
    };
  };
}
