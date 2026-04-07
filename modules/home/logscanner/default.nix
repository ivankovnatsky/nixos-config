{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.logscanner;

  configJson = pkgs.writeText "logscanner-agent-config.json" (
    builtins.toJSON {
      inherit (cfg) logPaths patterns;
      inherit (cfg) discordWebhookFile;
      inherit (cfg) stateFile;
      scanSystemLog = false;
    }
  );
in
{
  options.local.services.logscanner = {
    enable = mkEnableOption "daily user log scanner with Discord alerts";

    hour = mkOption {
      type = types.int;
      default = 21;
      description = "Hour of day to run the scan (0-23)";
    };

    minute = mkOption {
      type = types.int;
      default = 0;
      description = "Minute of hour to run the scan (0-59)";
    };

    hours = mkOption {
      type = types.int;
      default = 24;
      description = "How many hours back to scan";
    };

    logPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Glob patterns for user log files to scan";
    };

    patterns = mkOption {
      type = types.listOf types.str;
      default = [
        "(?i)\\berror\\b"
        "(?i)\\bfatal\\b"
        "(?i)\\bpanic\\b"
        "(?i)\\bfailed\\b"
        "(?i)\\bcrash\\b"
      ];
      description = "Regex patterns to match in log files";
    };

    discordWebhookFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing Discord webhook URL";
    };

    stateFile = mkOption {
      type = types.str;
      default = "/tmp/logscanner-agent-last-run";
      description = "Path to state file for deduplication";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.logscanner = {
      enable = true;
      keepAlive = false;
      runAtLoad = false;
      waitForSecrets = cfg.discordWebhookFile != null;

      command =
        let
          scanScript = pkgs.writeShellScript "logscanner-agent-run" ''
            set -e
            echo "Running logscanner (user agent)..."
            ${pkgs.logscanner}/bin/logscanner \
              --config "${configJson}" \
              --hours ${toString cfg.hours}
            echo "Logscanner agent completed"
          '';
        in
        "${scanScript}";

      extraServiceConfig = {
        StartCalendarInterval = [
          {
            Hour = cfg.hour;
            Minute = cfg.minute;
          }
        ];
      };
    };
  };
}
