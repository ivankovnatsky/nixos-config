{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.gh}/bin/gh auth status >/dev/null 2>&1; then
      PATH="/usr/bin:$PATH" ${pkgs.gh}/bin/gh auth login --git-protocol https --web
    fi
  '';

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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "interactive";
    };
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
    # diff-highlight.enable = true;
    # difftastic.enable = true;
    # diff-so-fancy.enable = true;

    includes = [
      { path = "${./config}"; }
    ];

    settings = {
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
      # ghq config options: root, user, completeUser, <url>.vcs, <url>.root
      # https://github.com/x-motemen/ghq
      ghq = {
        root = "${config.flags.homeWorkPath}/Sources";
      };
      core = {
        editor = "${config.flags.editor}";
      };
      safe = {
        directory = "${config.flags.homeWorkPath}/Sources/github.com/ivankovnatsky/nixos-config";
      };
    };
  };
}
