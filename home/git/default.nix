{
  config,
  pkgs,
  lib,
  ...
}:

let
  ghAuthCheckZsh = ''
    # gh auth check - only if hosts.yml missing
    if [[ ! -f "$HOME/.config/gh/hosts.yml" ]] && command -v gh &>/dev/null; then
      gh auth login --git-protocol https --web
    fi
  '';

  ghAuthCheckFish = ''
    # gh auth check - only if hosts.yml missing
    if not test -f "$HOME/.config/gh/hosts.yml"; and command -v gh >/dev/null
      gh auth login --git-protocol https --web
    end
  '';
in
{
  # TODO: Explore commitizen (Python) for interactive commit messages
  # Supports --config flag: `cz --config ~/.cz.toml commit`
  # https://github.com/commitizen-tools/commitizen

  # Global git hooks for commit message validation
  home.file.".config/git/hooks/commit-msg" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      # Skip password-store repos (uses GPG signing with auto-generated messages)
      repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
      if [[ "$repo_path" == *"/password-store"* ]] || [[ "$repo_path" == *"/.password-store"* ]]; then
        exit 0
      fi

      commit_msg_file="$1"
      commit_msg=$(cat "$commit_msg_file")
      title=$(echo "$commit_msg" | head -1)

      # Skip merge commits
      if echo "$title" | grep -qE '^Merge '; then
        exit 0
      fi

      # Check title length (max 72 chars)
      title_len=''${#title}
      if [ "$title_len" -gt 72 ]; then
        echo "ERROR: Commit title must be ≤72 characters (got $title_len)"
        echo "Title: $title"
        exit 1
      fi

    '';
  };

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

  programs.zsh.initContent = ghAuthCheckZsh;
  programs.fish.interactiveShellInit = ghAuthCheckFish;

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
        hooksPath = "${config.home.homeDirectory}/.config/git/hooks";
      };
      safe = {
        directory = "${config.flags.homeWorkPath}/Sources/github.com/ivankovnatsky/nixos-config";
      };
    };
  };
}
