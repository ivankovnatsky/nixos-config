{
  config,
  lib,
  pkgs,
  ...
}:

let
  forgejoCredentialHelper = pkgs.writeShellScript "forgejo-credential-helper" ''
    # Git credential helper for Forgejo
    # Reads domain and username from sops and returns credentials if host matches
    DOMAIN_FILE="${config.sops.secrets.external-domain.path}"
    TOKEN_FILE="${config.sops.secrets.forgejo-token.path}"
    USERNAME_FILE="${config.sops.secrets.forgejo-user-name.path}"

    if [ ! -f "$DOMAIN_FILE" ] || [ ! -f "$TOKEN_FILE" ] || [ ! -f "$USERNAME_FILE" ]; then
      exit 0
    fi

    DOMAIN=$(cat "$DOMAIN_FILE")
    TOKEN=$(cat "$TOKEN_FILE")
    USERNAME=$(cat "$USERNAME_FILE")

    # Parse input from git
    host=""
    protocol=""
    while IFS='=' read -r key value; do
      case "$key" in
        host) host="$value" ;;
        protocol) protocol="$value" ;;
      esac
    done

    if [ "$host" = "forgejo.$DOMAIN" ] && [ "$protocol" = "https" ]; then
      echo "username=$USERNAME"
      echo "password=$TOKEN"
    fi
  '';
in
{
  # TODO: Explore commitizen (Python) for interactive commit messages
  # Supports --config flag: `cz --config ~/.cz.toml commit`
  # https://github.com/commitizen-tools/commitizen

  # Global git hooks for commit message validation
  home = {
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

        # Extract scope (everything before first ": ")
        scope=$(echo "$title" | sed -n 's/: .*//p')

        # Forbid commas in scope (split into separate commits instead)
        if echo "$scope" | grep -qF ','; then
          echo "ERROR: Commas not allowed in commit scope"
          echo "Title: $title"
          echo "Split into separate commits or use a general subject"
          exit 1
        fi

        # Forbid semicolons in title
        if echo "$title" | grep -qF ';'; then
          echo "ERROR: Semicolons not allowed in commit title"
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

    activation.forgejoGitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DOMAIN_FILE="${config.sops.secrets.external-domain.path}"
      USERNAME_FILE="${config.sops.secrets.forgejo-user-name.path}"
      if [ -f "$DOMAIN_FILE" ] && [ -f "$USERNAME_FILE" ]; then
        DOMAIN=$(cat "$DOMAIN_FILE")
        FORGEJO_USERNAME=$(cat "$USERNAME_FILE")
        mkdir -p "$HOME/.config/git"

        # User config for Forgejo repos
        cat > "$HOME/.config/git/forgejo.inc" << EOF
[user]
	name = $FORGEJO_USERNAME
	email = $FORGEJO_USERNAME@$DOMAIN
	signingKey = $FORGEJO_USERNAME@$DOMAIN
[commit]
	gpgSign = true
[tag]
	gpgSign = true
EOF

        # User config for GitHub repos
        cat > "$HOME/.config/git/github.inc" << EOF
[user]
	name = Ivan Kovnatsky
	email = 75213+ivankovnatsky@users.noreply.github.com
	signingKey = 75213+ivankovnatsky@users.noreply.github.com
[commit]
	gpgSign = true
[tag]
	gpgSign = true
EOF

        ${if config.flags.purpose == "home" then ''
        # Home machines: default to Forgejo, override for github.com repos
        cat > "$HOME/.config/git/forgejo-includes.inc" << EOF
[include]
	path = ~/.config/git/forgejo.inc
[includeIf "gitdir:${config.flags.homeWorkPath}/Sources/github.com/"]
	path = ~/.config/git/github.inc
EOF
        '' else ''
        # Work machines: no conditional includes, use default GitHub identity
        rm -f "$HOME/.config/git/forgejo-includes.inc"
        ''}
      fi
    '';

    activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      if pkgs.stdenv.hostPlatform.isDarwin then
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
        file-modified-label = "";
        file-renamed-label = "renamed:";
        right-arrow = " ";
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
        { path = "~/.config/git/forgejo-includes.inc"; }
      ];

      # Override git's default LESS=FRX: -F quits on short output, then Ctrl+D
      # (used to scroll in less) hits the shell and exits the terminal instead
      iniContent.core.pager = lib.mkForce "LESS=R delta";

      settings.credential.helper = "${forgejoCredentialHelper}";

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
          directory = "${config.flags.homeWorkPath}/Sources/github.com/ivankovnatsky/nix-config";
        };
      };
    };
  };
}
