{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.reposync;

  repoSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Display name for logs (defaults to basename of path)";
      };

      path = mkOption {
        type = types.str;
        description = "Absolute path to the local git repository";
      };

      remote = mkOption {
        type = types.str;
        default = "origin";
        description = "Git remote name to sync with";
      };

      remoteUrl = mkOption {
        type = types.str;
        description = "URL template for the git remote (use @domain@ and @username@ for runtime substitution)";
      };

      branch = mkOption {
        type = types.str;
        default = "main";
        description = "Branch to sync";
      };

      prune = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Pass --prune to git fetch for this repo. Removes stale
          remote-tracking refs that would otherwise block fetches with
          "some local refs could not be updated". Useful for one-way
          mirrors of upstream repos with churning branches.
        '';
      };

      syncMode = mkOption {
        type = types.enum [
          "pull-push"
          "push-only"
          "pull-only"
        ];
        default = "pull-push";
        description = ''
          Sync mode for this repository. Use "push-only" for iCloud-backed
          working copies that should publish local commits without pulling.
          Use "pull-only" for repos that should only fetch upstream changes.
        '';
      };

      autoStage = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Run `git add --all` before fetch/pull so untracked or modified
          working-tree files don't block the ff-only pull (incoming
          commits touching the same paths would otherwise refuse to
          merge with "untracked working tree files would be
          overwritten"). Does NOT commit. Intended for repos whose
          working tree is also written to by an external sync mechanism
          (e.g. Unison mirroring into the same path on multiple hosts).
          Only runs when HEAD is on the configured branch.
        '';
      };

      identity = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "user.name to enforce repo-locally (supports @domain@/@username@)";
              };
              email = mkOption {
                type = types.str;
                description = "user.email to enforce repo-locally (supports @domain@/@username@)";
              };
              signingKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "user.signingKey to enforce repo-locally (supports @domain@/@username@)";
              };
            };
          }
        );
        default = null;
        description = ''
          Git identity to enforce as repo-local config. Repo-local config
          outranks all global config, so commits made in this repo use
          this identity regardless of who or what commits.
        '';
      };
    };
  };

  configJsonTemplate = pkgs.writeText "reposync-config.json" (
    builtins.toJSON {
      inherit (cfg) repositories alertRepeatSeconds alertStateFile;
      inherit (cfg) discordWebhookFile;
    }
  );

  syncScript = pkgs.writeShellScript "reposync-run" ''
    set -e

    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.openssh
      ]
    }:$PATH"

    CONFIG="${configJsonTemplate}"

    ${optionalString (cfg.domainFile != null || cfg.usernameFile != null) ''
      CONFIG_DIR=$(mktemp -d)
      trap 'rm -rf "$CONFIG_DIR"' EXIT
      cp "$CONFIG" "$CONFIG_DIR/reposync-config.json"
      ${optionalString (cfg.domainFile != null) ''
        DOMAIN="$(cat ${cfg.domainFile})"
        ${pkgs.gnused}/bin/sed -i "s|@domain@|$DOMAIN|g" "$CONFIG_DIR/reposync-config.json"
      ''}
      ${optionalString (cfg.usernameFile != null) ''
        USERNAME="$(cat ${cfg.usernameFile})"
        ${pkgs.gnused}/bin/sed -i "s|@username@|$USERNAME|g" "$CONFIG_DIR/reposync-config.json"
      ''}
      CONFIG="$CONFIG_DIR/reposync-config.json"
    ''}

    echo "Running reposync..."
    ${pkgs.reposync}/bin/reposync sync \
      --config-file "$CONFIG" 2>&1 || echo "Warning: reposync failed with exit code $?"

    echo "Reposync completed"
  '';
in
{
  options.local.services.reposync = {
    enable = mkEnableOption "periodic git repository sync";

    interval = mkOption {
      type = types.int;
      default = 5 * 60;
      description = "Interval in seconds between sync runs (default: 5 minutes)";
    };

    alertRepeatSeconds = mkOption {
      type = types.int;
      default = 3 * 60 * 60;
      description = "Minimum seconds between repeated Discord alerts for the same failure";
    };

    alertStateFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file for storing alert suppression state (defaults to platform-specific path)";
    };

    runAtLoad = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to launch reposync immediately when the launchd job is loaded.
        Disable this to defer the first sync until the first StartInterval tick.
      '';
    };

    repositories = mkOption {
      type = types.listOf repoSubmodule;
      default = [ ];
      description = "Repositories to sync";
    };

    domainFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing domain for @domain@ substitution in remote URLs";
    };

    usernameFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing username for @username@ substitution in remote URLs";
    };

    discordWebhookFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing Discord webhook URL for failure notifications";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.reposync = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      keepAlive = false;
      inherit (cfg) runAtLoad;
      waitForSecrets =
        cfg.discordWebhookFile != null || cfg.domainFile != null || cfg.usernameFile != null;

      command = "${syncScript}";

      extraServiceConfig = {
        StartInterval = cfg.interval;
      };
    };

    # On NixOS, sops-nix is a system unit rendered in stage-2 boot (long before
    # any user unit starts), so secrets are already present and no user-level
    # dependency on it is needed or possible. We only order on the network.
    systemd.user.services.reposync = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Sync git repositories";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}";
      };
    };

    systemd.user.timers.reposync = mkIf pkgs.stdenv.isLinux {
      Unit.Description = "Run reposync periodically";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString cfg.interval}s";
        Persistent = true;
        Unit = "reposync.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
