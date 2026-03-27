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
        description = "URL template for the git remote (use @domain@ for runtime substitution from domainFile)";
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
        ];
        default = "pull-push";
        description = ''
          Sync mode for this repository. Use "push-only" for iCloud-backed
          working copies that should publish local commits without pulling.
        '';
      };
    };
  };

  configJsonTemplate = pkgs.writeText "reposync-config.json" (builtins.toJSON {
    repositories = cfg.repositories;
    discordWebhookFile = cfg.discordWebhookFile;
  });
in
{
  options.local.services.reposync = {
    enable = mkEnableOption "periodic git repository sync";

    interval = mkOption {
      type = types.int;
      default = 15 * 60;
      description = "Interval in seconds between sync runs (default: 15 minutes)";
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

        ${optionalString (cfg.domainFile != null) ''
          DOMAIN="$(cat ${cfg.domainFile})"
          CONFIG_DIR=$(mktemp -d)
          trap 'rm -rf "$CONFIG_DIR"' EXIT
          ${pkgs.gnused}/bin/sed "s|@domain@|$DOMAIN|g" "$CONFIG" > "$CONFIG_DIR/reposync-config.json"
          CONFIG="$CONFIG_DIR/reposync-config.json"
        ''}

        echo "Running reposync..."
        ${pkgs.reposync}/bin/reposync sync \
          --config-file "$CONFIG" 2>&1 || echo "Warning: reposync failed with exit code $?"

        echo "Reposync completed"
      '';

      path = [ pkgs.git pkgs.openssh ];
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
