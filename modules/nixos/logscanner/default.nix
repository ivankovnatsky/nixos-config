{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.logscanner;

  configJson = pkgs.writeText "logscanner-config.json" (
    builtins.toJSON {
      inherit (cfg) logPaths patterns;
      inherit (cfg) discordWebhookFile;
      inherit (cfg) stateFile;
      scanSystemLog = true;
    }
  );
in
{
  options.local.services.logscanner = {
    enable = mkEnableOption "daily log scanner with Discord alerts";

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
      description = "Glob patterns for log files to scan";
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
      default = "/tmp/logscanner-daemon-last-run";
      description = "Path to state file for deduplication";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.logscanner = {
      description = "Scan system logs for errors and alert via Discord";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        set -e
        echo "Running logscanner..."
        ${pkgs.logscanner}/bin/logscanner \
          --config "${configJson}" \
          --hours ${toString cfg.hours}
        echo "Logscanner completed"
      '';
    };

    systemd.timers.logscanner = {
      description = "Run logscanner daily";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "*-*-* ${toString cfg.hour}:${lib.fixedWidthString 2 "0" (toString cfg.minute)}:00";
        Persistent = true;
      };
    };
  };
}
