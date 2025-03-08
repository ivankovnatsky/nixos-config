{ config, ... }:

{
  imports = [ ../../modules/darwin/promtail ];

  services.promtail = {
    enable = true;
    dataDir = "/tmp/promtail";
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 9097;
      };
      positions = {
        filename = "/tmp/promtail/positions.yaml";
      };
      clients = [
        {
          # Point to your beelink machine's Loki instance
          url = "http://loki.beelink.home.lan:3100/loki/api/v1/push";
          # Add rate limiting to avoid overwhelming Loki
          batchwait = "1s";
          batchsize = 1048576; # 1MB batch size
          # Add backpressure as a safeguard
          backoff_config = {
            min_period = "500ms";
            max_period = "5m";
            max_retries = 10;
          };
        }
      ];
      # Rate limiting is handled by client configuration

      scrape_configs = [
        {
          job_name = "system_logs";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-system";
                host = "${config.networking.hostName}";
                __path__ = "/var/log/*.log";
              };
            }
          ];
        }
        {
          job_name = "var_logs_recursive";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-var";
                host = "${config.networking.hostName}";
                __path__ = "/var/log/**/*.log";
              };
            }
          ];
        }
        {
          job_name = "user_logs";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-user";
                host = "${config.networking.hostName}";
                __path__ = "/Users/*/Library/Logs/**/*.log";
              };
            }
          ];
        }
        {
          job_name = "application_logs";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-applications";
                host = "${config.networking.hostName}";
                __path__ = "/Library/Logs/**/*.log";
              };
            }
          ];
        }
        {
          job_name = "diagnostic_reports";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-diagnostics";
                host = "${config.networking.hostName}";
                __path__ = "/Library/Logs/DiagnosticReports/**/*.{log,crash,diag}";
              };
            }
          ];
        }
        {
          job_name = "user_diagnostic_reports";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "macos-user-diagnostics";
                host = "${config.networking.hostName}";
                __path__ = "/Users/*/Library/Logs/DiagnosticReports/**/*.{log,crash,diag}";
              };
            }
          ];
        }
      ];
    };
  };
}
