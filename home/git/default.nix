{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git-extras
    ghq
    git-crypt
    git-filter-repo
    (gh-notify.override {
      withBat = true;
      withDelta = true;
    })
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
    ignores = [
      "**/.venv"
      "**/venv"

      "**/.stignore"
      "**/.stfolder"

      "**/__worktrees/"

      "**/CLAUDE.md"
      "**/CLAUDE.local.md"
      "**/.claude"
      "**/claude/"
      "**/.serena"
    ];
    # delta = {
    #   enable = true;
    #   options = {
    #     features = "interactive";
    #   };
    # };
    # diff-highlight.enable = true;
    # difftastic.enable = true;
    # diff-so-fancy.enable = true;

    includes = [
      { path = "${./config}"; }
    ];

    extraConfig = {
      mergetool =
        let
          vimCommand = "vim -f -d -c 'wincmd J' \"$LOCAL\" \"$BASE\" \"$REMOTE\" \"$MERGED\"";
          neovimCommand = ''nvim -f -c "Gvdiffsplit!" "$MERGED"'';
          mergetoolOptions = {
            keepBackup = false;
            prompt = true;
          };
        in
        if config.flags.editor == "nvim" then
          {
            "fugitive".cmd = neovimCommand;
            tool = "fugitive";
          }
          // mergetoolOptions
        else
          {
            cmd = vimCommand;
          }
          // mergetoolOptions;
      merge.tool = if config.flags.editor == "nvim" then "fugitive" else "vimdiff";
      ghq = {
        root = "${config.flags.homeWorkPath}/Sources";
      };
      core = {
        editor = "${config.flags.editor}";
      };
    };
  };
}
