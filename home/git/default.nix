{
  config,
  lib,
  pkgs,
  ...
}:

{
  # TODO: Explore commitizen (Python) for interactive commit messages
  # Supports --config flag: `cz --config ~/.cz.toml commit`
  # https://github.com/commitizen-tools/commitizen

  # Global git hooks for commit message validation
  home = {
    # Require explicit file/dir paths on every commit. Prevents AI agents
    # from accidentally committing concurrent work by other agents on the
    # same repo. Git worktrees solve this in theory, but they use absolute
    # paths that break cross-platform (Linux/macOS) setups and complicate
    # Nix rebuilds.
    file.".config/git/hooks/pre-commit" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        set -euo pipefail

        # Skip password-store repos
        repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ "$repo_path" == *"/password-store"* ]] || [[ "$repo_path" == *"/.password-store"* ]]; then
          exit 0
        fi

        # When git commit <file-or-dir> is used, GIT_INDEX_FILE points to a temp index
        # When git commit (no file) is used, GIT_INDEX_FILE is empty or .git/index
        if [[ -z "''${GIT_INDEX_FILE:-}" || "$GIT_INDEX_FILE" == *".git/index" ]]; then
          echo "ERROR: Must specify file(s) or dir/ to commit" >&2
          echo "Use: git commit <file> -m \"message\"" >&2
          echo "  or: git commit <dir/> -m \"message\"" >&2
          exit 1
        fi
      '';
    };

    file.".config/git/hooks/commit-msg" = {
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

    packages = with pkgs; [
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
    sessionVariables = {
      GIT_CONFIG_NOSYSTEM = "true";
    };

    activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      if pkgs.stdenv.isDarwin then
        ''
          if [ ! -f "$HOME/.config/gh/hosts.yml" ] || ! /usr/bin/security find-generic-password -s "gh:github.com" -w >/dev/null 2>&1; then
            PATH="/usr/bin:$PATH" ${pkgs.gh}/bin/gh auth login --git-protocol https --web
          fi
        ''
      else
        ''
          if [ ! -f "$HOME/.config/gh/hosts.yml" ]; then
            ${pkgs.gh}/bin/gh auth login --git-protocol https --web
          fi
        ''
    );
  };

  programs = {
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = { };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        features = "interactive";
        line-numbers = true;
        wrap-max-lines = "unlimited";
        max-line-length = 0;
        navigate = true;
        pager = "less -R";
      };
    };

    # https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix#L102
    git = {
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

      # Override git's default LESS=FRX: -F quits on short output, then Ctrl+D
      # (used to scroll in less) hits the shell and exits the terminal instead
      iniContent.core.pager = lib.mkForce "LESS=R delta";

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
  };
}
