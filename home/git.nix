{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git-extras
    ghq
    git-crypt
    git-filter-repo
    (gh-notify.override { withBat = true; withDelta = true; })
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

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix#L102
  programs.git = {
    enable = true;
    inherit (config.flags.git) userName userEmail;
    signing = {
      signByDefault = true;
      key = config.flags.git.userEmail;
    };
    ignores = [
      "**/.venv"
      "**/venv"
      "**/.stignore"
      "**/.stfolder"
      "**/__worktrees/"
    ];
    delta.enable = true;
    # diff-highlight.enable = true;
    # difftastic.enable = true;
    # diff-so-fancy.enable = true;
    aliases = {
      a = "add";
      co = "checkout";
      c = "commit -v";
      ca = "commit -av";
      d = "diff HEAD"; # This will show all changes
      l = "log --oneline -n 20";
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
      diff.noprefix = true;
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
