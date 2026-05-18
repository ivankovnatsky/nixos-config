{
  config,
  lib,
  pkgs,
  username,
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
    };
  };

  configJsonTemplate = pkgs.writeText "reposync-config.json" (
    builtins.toJSON {
      inherit (cfg) repositories alertRepeatSeconds alertStateFile;
      inherit (cfg) discordWebhookFile;
    }
  );
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
    systemd.services.reposync = {
      description = "Sync git repositories";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = username;
      };

      script = ''
        set -e

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

      path = [
        pkgs.git
        pkgs.openssh
      ];
    };

    systemd.timers.reposync = {
      description = "Run reposync periodically";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString cfg.interval}s";
        Persistent = true;
      };
    };
  };
}
